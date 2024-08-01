defmodule EtheloApi.Graphql.Schemas.DecisionTest do
  @moduledoc """
  Test graphql queries for Decisions
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag decision: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.DecisionHelper
  import EtheloApi.TestHelper.ImportHelper, only: [valid_import: 0]

  alias EtheloApi.Blueprints.SimpleDecision
  alias EtheloApi.Invocation
  alias EtheloApi.Scenarios.Factory, as: ScenariosFactory
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  describe "decisions query" do
    test "without filter returns all records" do
      to_match1 = create_decision()
      to_match2 = create_decision()

      query = """
        {
          decisions {
            copyable
            id
            info
            insertedAt
            language
            maxUsers
            slug
            updatedAt
            title
          }
        }
      """

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decisions"])

      assert [_, _] = result

      assert_result_ids_match([to_match1, to_match2], result)
    end
  end

  describe "decision => summary query" do
    test "filters by id " do
      create_decision()
      to_match = create_decision()

      query = ~s|
        query($decisionId: ID!){
          decision(
            decisionId: $decisionId
          )
          {
            meta {
              successful
              messages{
                message
              }
            }
            summary{
              id

            }
          }
        }
      |

      response = evaluate_graphql(query, variables: %{"decisionId" => to_match.id})

      assert {:ok, %{data: data}} = response
      summary = get_in(data, ["decision", "summary"])
      assert_equivalent_graphql(to_match, summary, fields([:id]))

      meta = get_in(data, ["decision", "meta"])
      assert %{"successful" => true, "messages" => []} = meta
    end

    test "filters by slug" do
      create_decision()
      to_match = create_decision()

      query = ~s|
        {
          decision(
            decisionSlug: "#{to_match.slug}"
          )
          {
            summary{
              slug
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"slug" => slug} = result
      assert to_string(to_match.slug) == slug
    end

    test "no matching records" do
      decision = create_decision()
      delete_decision(decision)

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              id
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      meta = get_in(data, ["decision", "meta"])
      assert %{"successful" => false, "messages" => [message]} = meta
      assert %{"message" => "does not exist", "field" => "filters"} = message
      summary = get_in(data, ["decision", "summary"])
      assert nil == summary
    end
  end

  describe "calculated fields" do
    test "export" do
      decision = create_decision()

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              export
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"export" => export} = result
      assert is_binary(export)
    end

    test "Decision cache exists" do
      decision = create_decision()

      ScenariosFactory.create_cache(decision, %{
        key: Invocation.decision_key(),
        value: "fobar"
      })

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              cachePresent
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"cachePresent" => true} = result
    end

    test "Decision cache missing" do
      decision = create_decision()

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              cachePresent
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"cachePresent" => false} = result
    end

    test "ScenarioConfig cache exists" do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      ScenariosFactory.create_cache(decision, %{
        key: Invocation.scenario_config_key(scenario_config.id),
        value: "fobar"
      })

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              configCachePresent(
                scenarioConfigId: #{scenario_config.id}
              )
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"configCachePresent" => true} = result
    end

    test "ScenarioConfig cache  missing" do
      %{decision: decision, scenario_config: scenario_config} = create_scenario_config()

      query = ~s|
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            meta {
              successful
              messages{
                message
                field
              }
            }
            summary{
              configCachePresent(
                scenarioConfigId: #{scenario_config.id}
              )
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "summary"])
      assert %{"configCachePresent" => false} = result
    end

    test "Solve Files" do
      query = ~s|
        query(
          $decisionId: ID!
          $scenarioConfigId: ID!
          $useCache: Boolean
        ){
          decision(
            decisionId: $decisionId
          )
          {
            summary{
              solveFiles(
                scenarioConfigId: $scenarioConfigId
                useCache: $useCache
              )
              {
                configJson
                decisionJson
                influentsJson
                weightsJson
                hash
              }
            }
          }
        }
      |

      %{decision: decision, scenario_config: scenario_config} = SimpleDecision.build()

      params =
        %{
          "decisionId" => decision.id,
          "scenarioConfigId" => scenario_config.id,
          "useCache" => false
        }

      response = evaluate_graphql(query, variables: params)

      assert {:ok, %{data: data}} = response
      solve_files = get_in(data, ["decision", "summary", "solveFiles"])

      refute is_nil(Map.get(solve_files, "configJson"))
      refute is_nil(Map.get(solve_files, "decisionJson"))
      refute is_nil(Map.get(solve_files, "influentsJson"))
      refute is_nil(Map.get(solve_files, "weightsJson"))
      refute is_nil(Map.get(solve_files, "hash"))
    end
  end

  describe "createDecision mutation" do
    test "creates with valid data" do
      input = %{
        title: "Moogle",
        info: "Moogle Moogle",
        copyable: true,
        max_users: 50,
        language: "en"
      }

      query = ~s|
        mutation{
          createDecision(
            input: {
              title: "#{input.title}"
              info: "#{input.info}"
              language: "#{input.language}"
              copyable: #{input.copyable}
              maxUsers: #{input.max_users}
            }
          )
          {
            successful
            result {
              id
              title
              info
              copyable
              language
              maxUsers
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createDecision" => payload} = data

      assert_mutation_success(
        input,
        payload,
        fields([:title, :info, :copyable, :language, :max_users])
      )

      assert %Decision{} = Structure.get_decision(payload["result"]["id"])
    end

    test "invalid data returns errors" do
      input = %{
        title: "-",
        slug: "A"
      }

      query = ~s|
        mutation{
          createDecision(
            input: {
              title: "#{input.title}"
              slug: "#{input.slug}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"createDecision" => payload} = data

      expected = %ValidationMessage{
        code: :format,
        field: :title,
        message: "must include at least one word"
      }

      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "importDecision mutation" do
    test "creates with valid data" do
      query = ~s|
      mutation (
        $title: String!
        $slug: String!
        $info: String
        $keywords: [String]
        $language: String
        $json_data: String!
      ) {
        importDecision(
          input: {
            title: $title
            slug: $slug
            info: $info
            keywords: $keywords
            language: $language
            jsonData: $json_data
          }
        )
        {
          successful
          result {
            id
            title
            slug
          }
        }
      }
      |

      input = %{
        "title" => "Moogle",
        "info" => "Moogle Moogle",
        "language" => "en",
        "slug" => "moooo",
        "keywords" => ["imported"],
        "json_data" => valid_import()
      }

      response = evaluate_graphql(query, variables: input)

      assert {:ok, %{data: data}} = response
      assert %{"importDecision" => payload} = data

      assert_mutation_success(
        input,
        payload,
        fields([:title, :slug])
      )

      assert %Decision{} = Structure.get_decision(payload["result"]["id"])
    end

    test "invalid json_data returns errors" do
      input = %{
        title: "Moogle",
        info: "Moogle Moogle",
        language: "en",
        slug: "moooo",
        keywords: ~s|[\\"imported\\"]|,
        json_data: "{}"
      }

      query =
        ~s|
        mutation{
          importDecision(
            input: {
              title: "#{input.title}"
              info: "#{input.info}"
              language: "#{input.language}"
              slug: "#{input.slug}"
              keywords: "#{input.keywords}"
              json_data: "#{input.json_data}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
        |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"importDecision" => payload} = data

      expected = %ValidationMessage{
        code: :import_file,
        field: :jsonData,
        message: "is invalid"
      }

      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "copyDecision mutation " do
    test "copies with valid data" do
      to_copy = create_decision()

      input = %{
        title: "Moogle",
        slug: "mooo",
        info: "Moogle Moogle",
        language: "en",
        keywords: "",
        decision_id: to_copy.id
      }

      query = ~s|

          mutation{
            copyDecision(
              input: {
                decisionId: #{input.decision_id}
                title: "#{input.title}"
                info: "#{input.info}"
                language: "#{input.language}"
                slug: "#{input.slug}"
                keywords: "#{input.keywords}"
              }
            )
            {
              successful
              result {
                id
                title
                slug
              }
            }
          }
        |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"copyDecision" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :slug]))
      assert %Decision{} = Structure.get_decision(payload["result"]["id"])
    end

    test "invalid data returns errors" do
      to_copy = create_decision()

      input = %{
        title: "-",
        slug: "A",
        decision_id: to_copy.id
      }

      query = ~s|
        mutation{
          copyDecision(
            input: {
              decisionId: #{input.decision_id}
              title: "#{input.title}"
              slug: "#{input.slug}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"copyDecision" => payload} = data

      expected = %ValidationMessage{
        code: :format,
        field: :title,
        message: "must include at least one word"
      }

      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "updateDecision mutation " do
    test "updates with valid data" do
      to_update = create_decision()

      input = %{
        title: "Moogle",
        info: "Moogle Moogle",
        copyable: true,
        max_users: 50,
        language: "en",
        id: to_update.id
      }

      query = ~s|

          mutation{
            updateDecision(
              input: {
                id: #{input.id}
                title: "#{input.title}"
                info: "#{input.info}"
                language: "#{input.language}"
                copyable: #{input.copyable}
                maxUsers: #{input.max_users}
              }
            )
            {
              successful
              result {
                id
                title
                info
                language
                copyable
                maxUsers
              }
            }
          }
        |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateDecision" => payload} = data
      assert_mutation_success(input, payload, fields([:title, :info, :copyable, :max_users]))
    end

    test "invalid data returns errors" do
      to_update = create_decision()

      input = %{
        title: "-",
        slug: "A",
        id: to_update.id
      }

      query = ~s|
        mutation{
          updateDecision(
            input: {
              id: #{input.id}
              title: "#{input.title}"
              slug: "#{input.slug}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              id
            }
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateDecision" => payload} = data

      expected = %ValidationMessage{
        code: :format,
        field: :title,
        message: "must include at least one word"
      }

      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "cacheDecision mutation " do
    test "updates" do
      decision = create_decision()

      query = ~s|

      mutation{
        cacheDecision(
          input: {
            id: #{decision.id}

          }
        )
        {
          successful
          result {
            id
            cachePresent
          }
        }
      }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"cacheDecision" => payload} = data
      assert_mutation_success(%{cache_present: true}, payload, fields([:cachePresent]))
      refute nil == Invocation.get_decision_cache_value(decision.id)
    end

    test "missing decision returns errors" do
      to_delete = create_decision()
      delete_decision(to_delete)

      query = ~s|
      mutation{
        cacheDecision(
          input: {
            id: #{to_delete.id}

          }
        ){
          successful
          messages {
            field
            message
            code
          }
          result {
            id
            cachePresent
          }
        }
      }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"cacheDecision" => payload} = data

      expected = %ValidationMessage{
        code: :not_found,
        field: :id,
        message: "does not exist"
      }

      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteDecision mutation" do
    test "deletes" do
      to_delete = create_decision()
      input = %{id: to_delete.id}

      query = ~s|
        mutation{
          deleteDecision(
            input: {
              id: #{input.id}
            }
          ){
            successful
          }
        }
      |

      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteDecision" => %{"successful" => true}} = data
      assert nil == Structure.get_decision(to_delete.id)
    end
  end
end
