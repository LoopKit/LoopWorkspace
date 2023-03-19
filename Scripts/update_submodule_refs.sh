#!/bin/zsh

projects=(LoopKit:AmplitudeService:dev LoopKit:CGMBLEKit:dev LoopKit:G7SensorKit:main LoopKit:LogglyService:dev LoopKit:Loop:dev LoopKit:LoopKit:dev LoopKit:LoopOnboarding:dev LoopKit:LoopSupport:dev LoopKit:NightscoutAPIClient:master ps2:NightscoutService:dev LoopKit:OmniBLE:dev LoopKit:TidepoolKit:dev LoopKit:TidepoolService:dev LoopKit:dexcom-share-client-swift:dev ps2:rileylink_ios:dev)

for project in ${projects}; do
  echo "Prepping $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  git checkout $branch
  git pull
  cd -
done

