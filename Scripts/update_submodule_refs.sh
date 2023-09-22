#!/bin/zsh

projects=(LoopKit:AmplitudeService:dev LoopKit:CGMBLEKit:dev LoopKit:G7SensorKit:main LoopKit:LogglyService:dev LoopKit:Loop:dev LoopKit:LoopKit:dev LoopKit:LoopOnboarding:dev LoopKit:LoopSupport:dev LoopKit:NightscoutRemoteCGM:dev LoopKit:NightscoutService:dev LoopKit:OmniBLE:dev LoopKit:TidepoolService:dev LoopKit:dexcom-share-client-swift:dev ps2:RileyLinkKit:dev LoopKit:OmniKit:main LoopKit:MinimedKit:main LoopKit:LibreTransmitter:main LoopKit:MixpanelService:main) 

for project in ${projects}; do
  echo "Updating to $project"
  IFS=":" read user dir branch <<< "$project"
  echo "Updating to $branch on $user/$project"
  cd $dir
  git checkout $branch
  #git branch -D tidepool-sync
  git pull
  cd -
done

