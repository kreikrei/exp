using HTTP
using JSON
using GitHub
using LightGraphs
using ProgressMeter

mytoken = ENV["GITHUB_AUTH"]
myauth = GitHub.authenticate(mytoken)

Pkg.add(url="https://github.com/JuliaRegistries/General")
