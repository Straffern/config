{den, ...}: {
  den.aspects.profiles.video = {
    includes = [
      den.aspects.apps.obs-studio
      den.aspects.apps.audacity
      den.aspects.apps.kdenlive
      den.aspects.apps.davinci-resolve
      den.aspects.apps.webcamoid
    ];
  };
}
