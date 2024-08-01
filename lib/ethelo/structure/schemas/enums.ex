
import EctoEnum
defenum DetailFormatEnum, :detail_format, [:string, :integer, :float, :boolean, :datetime]
defenum ScoringModeEnum, :scoring_mode, [:none, :rectangle, :triangle]
defenum VotingStyleEnum, :voting_style, [:one, :range]

defenum VariableMethodEnum, :variable_method,
  [:count_selected, :count_all, :sum_selected, :mean_selected, :sum_all, :mean_all]

defenum ConstraintOperatorEnum, :constraint_operator,
  [:equal_to, :less_than_or_equal_to, :greater_than_or_equal_to, :between]

defenum DecisionLanguageEnum, :language, ["en", "es", "fr-ca", "mn", "zh-cn", "ru", "ar", "vi"]
