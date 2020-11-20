# LibVCX Demo iOS Project for Alice
This iOS demo project code is based on [vcx-skeleton-ios](https://github.com/sktston/vcx-skeleton-ios), and implements demo code for Alice on iOS simulator or actual devices. You can use any Faber demo in different wrappers ([python](https://github.com/hyperledger/indy-sdk/tree/master/vcx/wrappers/python3/demo) or [node](https://github.com/hyperledger/indy-sdk/tree/master/vcx/wrappers/node)) for testing. Internally, the application serializes and deserializes the vcx connection object between operations. 

## Prerequisites

#### Xcode
It requires the Xcode 11

#### Install Vcx framework
Run `pod install` from the root folder of the project. It's getting the Vcx framework from our private pod. The Vcx framework is written in Objective-C, so the project includes the Objective-C bridging header file ([VcxDemo-Bridging-Header.h](https://github.com/sktston/vcx-skeleton-ios/blob/master/VcxDemo/VcxDemo-Bridging-Header.h)) to expose Objective-C framework in the Swift project. ([Importing Objective-C into Swift](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift))

**Note**: This project adopts the [Combine framework](https://developer.apple.com/documentation/combine) in order to migrate existing Objective-C async callbacks to Future/Promise style architecture. This is implemented in the file [VcxWrapper.swift](https://github.com/sktston/vcx-skeleton-ios/blob/master/VcxDemo/VcxWrapper.swift), and they are used with a `flatMap` for sequencing asynchronouse operations in this demo application.

## Steps to run Demo

#### Cloud Agent
You need to start [NodeVCXAgency](https://github.com/AbsaOSS/vcxagencynode) in the remote host with a specific IP address rather than localhost

Update the `agncy_url` field in the [ViewController.swift](https://github.com/sktston/vcx-demo-ios/blob/master/VcxDemo/ViewController.swift) file with your cloud agent's url

#### Indy Pool
You would also like to start the [Indy Pool](https://github.com/hyperledger/indy-sdk#how-to-start-local-nodes-pool-with-docker) on a specific IP address with the same reason in the cloud agent. Alternatively, you may use some public Indy Pools available on the web. 

Update [genesis.txn](https://github.com/sktston/vcx-demo-ios/blob/master/VcxDemo/genesis.txn) file with the genesis transaction info of the indy pool you want to access.

#### Run the Alice Demo
1. Run the Faber with a different demo application
1. Click the `Provision` button to provision an agent, and initialize VCX. 
1. Copy the invitation from the Faber, and paste it in the Invitation field of the Alice Demo Application
1. Click the `Connection Request` button, and then click the `Update` button. --> Connection will be established
1. Issue a credential from Faber demo
1. Click the `Update` button to get a credential offer from Faber. After a few momoent, Faber sends the credential. 
1. Click the `Update` button again to get a credential from the cloud agent. 
1. In the Faber Demo, ask for proof request
1. Click the `Update` button in the Alice demo. Alice present the proof, and Faber will verify it and send the ack after that. 
1. Click the `Update` button in the Alice Demo. It will get an ack, and you are done.