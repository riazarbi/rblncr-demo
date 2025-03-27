# rblncr-demo
Demonstration of how to use [rblncr](https://github.com/riazarbi/rblncr) with GitHub Actions. 

## Usage

This demo rabalances an Alpaca paper account holdings to approximate the portfolio weights specified in the `model.yaml` file. It runs daily, using github actions cron.

Some data is persisted to csv files in the root of the repo, which you can use to visualise portoflio weights over time. 

You can fork this repo and try it out with your own Alpaca account. You'll need to add the repository secrets listed in the workflow file to your own repo. Make sure your actions are enabled, and then run the workflow.

## Disclaimer

**NOTE: I offer no guarantee whatsoever that this code works as intended.**
