# LibVCX Demo iOS Project for Alice
This iOS demo project code is based on [vcx-skeleton-ios](https://github.com/sktston/vcx-skeleton-ios), and implements demo code for Alice on iOS simulator or actual devices. You can use any Faber demo in different wrappers ([python](https://github.com/hyperledger/indy-sdk/tree/master/vcx/wrappers/python3/demo) or [node](https://github.com/hyperledger/indy-sdk/tree/master/vcx/wrappers/node)) for testing. Internally, the application serializes and deserializes the vcx connection object between operations. 

**Note**: If you checkout the [develop branch](https://github.com/sktston/vcx-demo-ios/tree/develop), there is a more sophisticated demo project that utilizes non-secret wallet APIs to save/retrieve VCX objects. Moreover, it downloads messages from the cloud agent, and processes them according to it's context. 

## Prerequisites

#### Xcode
It requires the Xcode 11

#### Install Vcx framework
Run `pod install` from the root folder of the project. It's getting the Vcx framework from our private pod. The Vcx framework is written in Objective-C, so the project includes the Objective-C bridging header file ([VcxDemo-Bridging-Header.h](https://github.com/sktston/vcx-skeleton-ios/blob/master/VcxDemo/VcxDemo-Bridging-Header.h)) to expose Objective-C framework in the Swift project. ([Importing Objective-C into Swift](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift))

**Note**: This project adopts the [Combine framework](https://developer.apple.com/documentation/combine) in order to migrate existing Objective-C async callbacks to Future/Promise style architecture. This is implemented in the file [VcxWrapper.swift](https://github.com/sktston/vcx-skeleton-ios/blob/master/VcxDemo/VcxWrapper.swift), and they are used with a `flatMap` for sequencing asynchronouse operations in this demo application.

**Note**: The prebuilt vcx.framework is built/hosted by [SK Telecom](https://www.sktelecom.com/index_en.html), and it contains some open PRs which introduce new APIs and bug fixes on top of the current [master branch](https://github.com/hyperledger/indy-sdk/tree/cd66e2ce69f29bfc19754ec2f66bae36f4293fb2) of [indy-sdk](https://github.com/hyperledger/indy-sdk)

- [#2195](https://github.com/hyperledger/indy-sdk/pull/2195): LibVCX iOS wrapper updates 
- [#2209](https://github.com/hyperledger/indy-sdk/pull/2209): VCX Wallet APIs 

## Steps to run Demo

#### Cloud Agent
You need to start [NodeVCXAgency](https://github.com/AbsaOSS/vcxagencynode) or [Dummy Cloud Agent](https://github.com/hyperledger/indy-sdk/tree/master/vcx/dummy-cloud-agent) in the remote host with a specific IP address rather than localhost

Update the `agncy_url` field in the [ViewController.swift](https://github.com/sktston/vcx-demo-ios/blob/master/VcxDemo/ViewController.swift) file with your cloud agent's url

#### Indy Pool
You would also like to start the [Indy Pool](https://github.com/hyperledger/indy-sdk#how-to-start-local-nodes-pool-with-docker) on a specific IP address with the same reason in the cloud agent. Alternatively, you may use some public Indy Pools available on the web. 

Update [genesis.txn](https://github.com/sktston/vcx-demo-ios/blob/master/VcxDemo/genesis.txn) file with the genesis transaction info of the indy pool you want to access.

#### Run the Alice Demo
1. Run the Faber with a different demo application
1. Click the `Provision` button to provision an agent, and initialize VCX. 
1. Copy the invitation from the Faber, and paste it in the Invitation field of the Alice Demo Application
1. Click the `Connection Request` button
1. After connection established, issue credential from Faber demo
1. Click the `Accept Offer` button in the Alice Demo Application, you will get a credential in a moment
1. In the Faber Demo, ask for proof request
1. Click the `Present Proof` button. Faber will verify the proof and send the ack after that. 
1. Alice Demo Application will get an ack, and you are done.