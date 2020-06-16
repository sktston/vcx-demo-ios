# LibVCX Skeleton iOS Project
This is the iOS skeleton project to use [LibVCX for iOS Wrapper](https://github.com/hyperledger/indy-sdk/tree/master/vcx/wrappers/ios) in your iOS Swift project.
It contains a Podfile that installs the Vcx framework including all necessary dependencies such as `libindy`, `libssl`, `libcrypto`, `libsodium`, and `libzmq`. It also contains some boilerplate code to use LibVCX for iOS Wrapper (Objective-C) in the Swift project.
You can just start to use LibVCX APIs in the project without any issues.

## Prerequisites
#### Xcode
It requires the Xcode 11

#### Install Vcx framework
Run `pod install` from the root folder of the project. It's getting the Vcx framework from our private pod. The Vcx framework is written in Objective-C, so the project includes the Objective-C bridging header file ([VcxDemo-Bridging-Header.h](https://github.com/sktston/vcx-skeleton-ios/blob/master/VcxDemo/VcxDemo-Bridging-Header.h)) to expose Objective-C framework in the Swift project. ([Importing Objective-C into Swift](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift))

**Note**: You would like to look at [commit history](https://github.com/sktston/vcx-skeleton-ios/commits/master) in order to get more details what is done after creating a defualt single view project in Xcode.

## Steps to run project
#### Open the project
Open the `VcxDemo.xcworkspace` in the Xcode

#### Build  
Build the project

#### Run
If you see the empty single view application, you are done. 