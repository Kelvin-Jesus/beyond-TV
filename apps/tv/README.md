# beyond_tv

Player do Beyond TV para Android TV (Flutter). Recebe o conteúdo do servidor
local e exibe sites, imagens, vídeos e playlists em tela cheia.

```sh
flutter run            # com o emulador Android TV aberto
flutter build apk --debug
```

O app aparece na home da TV pelo `LEANBACK_LAUNCHER` e usa o banner de
320×180 px em `android/app/src/main/res/drawable-xhdpi/banner.png`.
