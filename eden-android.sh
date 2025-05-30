#!/bin/bash -ex

# We really need to hanlde this due to frequent failure of submodule update
clone_eden() {
	# Clone Eden, fallback to mirror if upstream repo fails to clone
	if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
		echo "Using mirror instead..."
		rm -rf ./eden || true
		git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
	fi
}

for try in {1..5}; do
	echo "=== Try #$try ==="
	rm -rf ./eden
	clone_eden
	cd ./eden

	if git submodule update --init --recursive; then
		echo "Submodule update succeeded! You are saved!"
		break
	fi

	echo "Submodule update failed! Your CI will reboot in 30 second..."
	cd ..
	sleep 30

	if [ "$try" -eq 5 ]; then
		echo "Submodule update failed after 5 retries! Your CI will explode right away! Run!!!"
		exit 1
	fi
done

COUNT="$(git rev-list --count HEAD)"
APK_NAME="Eden-${COUNT}-Android-Universal"

cd src/android
chmod +x ./gradlew
./gradlew assembleRelease --console=plain --info -Dorg.gradle.caching=true

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: APK not found in expected directory."
    exit 1
fi
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"
