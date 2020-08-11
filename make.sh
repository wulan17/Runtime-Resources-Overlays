#!/bin/bash
export TELEGRAM_CHAT
export TELEGRAM_TOKEN
export KEYSTORE_PASS
export GITTOKEN
export app_name="BatteryHealthOverlay"
sudo apt-get update -y
sudo apt install aapt zip unzip wget zipalign apksigner git -y
wget --quiet https://dl.google.com/android/repository/platform-29_r05.zip
unzip platform-29_r05.zip > /dev/null
git clone https://wulan17:"$GITTOKEN"@github.com/wulan17/credentials

aapt package -M AndroidManifest.xml -S res/ \
    -I android-10/android.jar \
    -F "$app_name".apk.u
if [ -e "$app_name".apk.u ]; then
	zipalign 4 "$app_name".apk.u "$app_name".apk.z
	if [ -e "$app_name".apk.z ]; then
		apksigner sign --ks credentials/wulan17.keystore --ks-pass pass:"$KEYSTORE_PASS" --out "$app_name".apk "$app_name".apk.z
		if [ -e "$app_name".apk ]; then
			mkdir out/system/product/overlay/"$app_name"
			chmod 0755 out/system/product/overlay/"$app_name"
			cp "$app_name".apk out/system/product/overlay/"$app_name"/
			cd out
			zip -r "$app_name".zip *
			curl -F "chat_id=$TELEGRAM_CHAT" -F document=@"$(pwd)"/"$app_name".zip https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendDocument
			exit 0
		else
			curl -F "chat_id=$TELEGRAM_CHAT" -F "text=Sign failed" https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendMessage
			exit 1
		fi
	else
		curl -F "chat_id=$TELEGRAM_CHAT" -F "text=Zipalign failed" https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendMessage
		exit 1
	fi
else
	curl -F "chat_id=$TELEGRAM_CHAT" -F "text=Build failed" https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendMessage
	exit 1
fi
