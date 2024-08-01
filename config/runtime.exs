import Config

if Config.config_env() == :dev || Config.config_env() == :test do
  DotenvParser.load_file(".env")
end


end
