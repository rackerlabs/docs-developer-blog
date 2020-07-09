---
layout: post
title: iOS Security Key Signing
date: '2013-05-28 08:35'
comments: true
author: Tokunbo George
published: true
categories: 
  - General
---
{% img right 2013-05-28-ios-security-key-signing/xcode_icon.png 200 %}
At Rackspace, we're working very hard to support the ever-growing platform of mobile. We're working hard to design a cloud-based mobile platform for developers and on the next generation of our mobile applications. Over the years we have developed a number mobile applications to interact with our services, but we recently made a conscious decision to improve them to more "fanatical" standards.

<!-- more -->

Possibly one of the hardest things about mobile testing is the infrastructure needed to support it. There are various vendors that provide some of this infrastructure, but there are few established best practices for how to build things in-house if you want to do more than run your tests on a local simulator. While we plan to rely on some of the work our friends at [Sauce Labs][1] have been cooking up, we also built a sizable chunk of testing infrastructure in-house.

Because of the lack of shared knowledge, we spent a good deal of time figuring things out the hard way. We now want to share with you some of the nasty details that we have overcome in this battle.<!-- more -->

### Encryption: That's the key

The hardest thing we ran into for our iOS setup is the iOS security key signing. The security key signing is essential when we automate the deployment and testing of a physical iOS device (rather than testing on the simulator, which doesn't require these extra steps). We'll discuss what we did to overcome this issue and share a little bit about our Jenkins setup in the process.

There are three main parts to testing new code on a physical device:

* Compile: Jenkins polls GitHub and compiles your new code
* Deploy: Use fruitstrap to move the .app to the phone
* Test: Use [Selenium][2] and [Appium][3] to run a test on that device

Here, we’ll focus mainly on the first part of the process: compilation. Let us know, however, if you'd like us to expand upon deployment and testing beyond what's in this article.

### Compilation basics:

Compilation for automated builds into physical devices isn't terribly difficult — it's just nit-picky and requires three little pieces of data to match-up:

1. login.keychain
2. CODE_SIGN_IDENTITY
3. PROVISIONING_PROFILE

##The Code You'll Need

When it comes to the actual build step, it will look like this:

```bash
security list-keychains

security unlock-keychain -p <YOURPASSWORD> \
> $HOME/Library/Keychains/login.keychain

/usr/bin/xcodebuild -target "Rackspace Cloud" –configuration \
> Release CODE_SIGNING_REQUIRED=Y \
> CODE_SIGN_IDENTITY="iPhone Developer: \
> Firstname Lastname (XXXXXXXXXX)" \
> PROVISIONING_PROFILE="2823AD7F-XXXX-XXXX-XXXX-XXXXXXXXXXX"
```

Yeah, it’s only a few commands - three whole lines. Should be simple, right?

Well, there isn't a ton of documentation out there, which is why I'm writing this blog post. Hopefully it WILL be simple by the time I'm done.

Taking each line in turn:

```bash
security list-keychains
```

The reason this command is there is for debugging. The reason debugging is nice is because when Jenkins runs a job on OSX, the loginkeys available are different from the loginkeys when you ssh. In particular, the login.keychain is locked when Jenkins runs a job under the build user. It is useful to see what was happening, although you can remove this command without causing harm.

```bash
security unlock-keychain -p <YOURPASSWORD> \
> $HOME/Library/Keychains/login.keychain
```

Using `ssh` or physically logging in at the machine unlocks your **login.keychain**. Jenkins jobs don't ([see this URL][4] for a good explanation). Instead, we unlock the keychain explicitly. If we don't, the code signing in the xcodebuild command causes OSX to give a popup window asking if xcodebuild has permission to sign code on your behalf. Because Jenkins jobs have no UI, the popup cannot appear and you'll see this in the build log: "user interaction is not allowed." This is OSX's way of saying "I tried to give a popup window to a process that had no GUI to see it."

```bash
/usr/bin/xcodebuild -target "Rackspace Cloud" –configuration \
> Release CODE_SIGNING_REQUIRED=Y \ 
> CODE_SIGN_IDENTITY="iPhone Developer: \
> Firstname Lastname (XXXXXXXXXX)" \
> PROVISIONING_PROFILE="2823AD7F-XXXX-XXXX-XXXX-XXXXXXXXXXX"
```

This is the actual build command. I'll take this one apart option by option:

`-target`

The build target inside the code. It's the same thing you see when you launch the XCode GUI and build to a particular target project.

`-configuration`

The build configuration that you normally see in the XCode GUI's build configuration screen. I believe “Release & Debug” are basic defaults. See screenshot xcode_build_target_and_stuff.png

`-CODE_SIGN_IDENTITY`

This string comes from the certificate that Apple gives you upon request.

`-PROVISIONING_PROFILE`

This file comes from Apple too. You can create and download one relatively easily.

### Steps for getting the data

First, that `CODE_SIGN_IDENTITY` string. Where did that come from? Here are the steps to get it:

1. Sign up for a developer account on Apple's website.
2. Follow this cookbook: <http://cookbook.gamesalad.com/tutorials/3/parts/12>
3. When you complete step No. 15, "On your local machine, double-click the downloaded .cer file to launch Keychain Access and install your certificate."
4. After installing your certificate, the name displayed in the KeychainAccess is the same string you should give CODE_SIGN_IDENTITY. See screenshot keychainaccess.png
5. Next, take the physical iOS device you have and plug it into the Mac
6. Start up Xcode
7. Navigate to “Windows -> Organizer -> Devices”
8. Click "Use this device for development." It will ask for your Apple-developer password
9. A provisioning profile should be created and placed onto your device (and added to your account for later downloading)

Next, that crazy `PROVISIONING_PROFILE` string. Where is that from?

1. Login to <http://developer.apple.com>
2. Click “iOS Provisioning Portal”
3. Click "Provisioning"
4. Click the "Development" tab
5. You should be at a list of provision profiles for your account. If the list is empty, click "New Profile" and follow the instructions. Be sure to put a checkmark on your certificate! This would be on a new screen that appears after clicking "New profile". There really should be a provisioning profile already created for you when you added an iOS device to your account in step No. 3 of the CODE_SIGN_IDENTITY instructions. If for some reason (that I don't really understand) a provisioning file wasn't created, you'll have to just do it manually and then download that file:

Navigate to “Xcode -> Windows -> Organizer -> Devices,” click on the iOS device, click "provisioning profiles" and finally drag and drop the provisioning file from desktop/Finder onto the Organizer you are currently viewing. Got all that?

6. Download the provisioning file. It will probably be named `<somestringyougave>.mobileprovision`

7. Now, use a hexeditor or vim or emacs or whatever to look inside this file. The file is not plain text, so this will look kind of crazy.

8. What you're looking for in this file is text that looks like this: `<key>UUID</key>`. Right below it should be a `<string>2823AD7F-XXXX-XXXX-XXXX-XXXXXXXXXXX</string>`. We call this the `<really_long_uuid_string>`

9. Exit your file-viewing program

10. Rename the provisioning file to be <really_long_uuid_string>.mobileprovision

11. Copy this file into `$HOME/Library/MobileDevice/Provisioning Profiles/`

**Note**: This is the invisible Library folder in your HOME folder, not the one at the root of the volume. You can reach it via Terminal.

### Back in Jenkins

Now we want to wrap all of this stuff up in Jenkins. Note, we are not going to use the Xcode plugin (see below for explanation).* 

To start in Jenkins, just do a freestyle job and add an "Execute Shell" step and paste in the xcodebuild command we mentioned earlier:

```bash
security list-keychains

security unlock-keychain -p <YOURPASSWORD> \
> $HOME/Library/Keychains/login.keychain

/usr/bin/xcodebuild -target "Rackspace Cloud" –configuration \
> Release CODE_SIGNING_REQUIRED=Y \
> CODE_SIGN_IDENTITY="iPhone Developer: \
> Firstname Lastname (XXXXXXXXXX)" \
> PROVISIONING_PROFILE="2823AD7F-XXXX-XXXX-XXXX-XXXXXXXXXXX"
```

But of course, change all the bits of data to match your own needs. This will get you as far as compiling.

### Using Fruitstrap to deploy

So, now you have a properly signed app that will work on your device. How would you automate installing it onto your physical device? We use Fruitstrap to navigate this part of the process. We also set up Appium to run on the device so we're ready for testing.

1. Get fruitstrap from the [unprompted repo][5]: 
2. Set up a Mac as a Jenkins slave (or run Jenkins on a Mac master)
3. Make sure the iOS device is connected to the Mac Jenkins machine via USB
4. Run this command:

```bash
fruitstrap -i <UUID_OF_PHONE_NOT_PROVISIONFILE> -b \
> ${WORKSPACE}/build/<target-build>/yourapp 
```

… or wherever xcodebuild ended up creating your .app dir.

5\. Then run:

```
appium -U <UUID_OF_PHONE_NOT_PROVISIONFILE> --app \
> <BUNDLE_ID_OF_APP> -a 0.0.0.0 -p 4446 –V
```

**Note**: BundleID of app is found inside XCode. Ask your favorite fellow developer if you don't know/can't find it. Basically search all files in the project.app dir for the string "CFBundleIdentifier." Right below this string should be the actual value.

And that’s it! Simple! You should now have your app loaded on your physical iOS device and ready to test.

Just a quick note: the Appium project is working on using iDeviceInstaller instead of Fruitstrap. We will probably migrate to using that tool soon, too.

### What’s next?

Try it! ... and then tell us where our instructions are lacking. We'll be happy to fill in the gaps. We know that this stuff is no walk in the park and it’s pretty tricky to describe the details efficiently, too.

Lastly, let us know if you find this helpful. We have other pieces of infrastructure to share: multiple Android emulators starting from a shared snapshot (running on Rackspace cloud machines, naturally...), iOS emulators, automated Android physical device testing, our comparison of various tools and rationale for choices and more. Tell us what subjects you're interested in hearing about next.

*A quick word about the Jenkins Xcode plugin and why it will not work for our purposes today: The plugin does not support spaces in the build variables. We need spaces in the build variables, so we can't use it. In particular, the `CODE_SIGN_IDENTITY` parameter will always have "iPhone Developer:" as the beginning of the string. It has spaces, so the plugin fails. The notes for this [are here][6].*

_Tokunbo "Toks" George misspent his youth daringly hacking on Apple II computers and all manner of video game consoles. For the past decade he has channeled his skillz towards quality engineering helping companies move from manual drudgery to automated utopia. He now spends his time at Rackspace furiously investigating the darkest corners of mobile devices and testing tools. While you were reading this blog post, it is more than likely that Tokunbo was watching anime or playing [Dance Dance Revolution][7]._

[1]: https://saucelabs.com/
[2]: http://docs.seleniumhq.org/
[3]: http://appium.io/
[4]: http://stackoverflow.com/questions/6416121/keychain-wont-unlock-from-jenkins-script-unless-user-logged-in
[5]: https://github.com/unprompted/fruitstrap
[6]: https://wiki.jenkins-ci.org/display/JENKINS/Xcode+Plugin
[7]: https://en.wikipedia.org/wiki/Dance_Dance_Revolution
