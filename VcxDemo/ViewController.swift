//
//  ViewController.swift
//  VcxDemo
//
//  Created by Jeong Kim on 16/06/2020.
//  Copyright © 2020 SK Telecom. All rights reserved.
//

import UIKit
import Combine
import SwiftyJSON

class ViewController: UIViewController {
    var cancellable: AnyCancellable?
    var did = ""

    @IBOutlet var txtInvitation: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnProvision(_ sender: UIButton) {
        let vcx = VcxWrapper()

        let provisionConfig = """
            {
              "agency_url": "http://13.125.5.122:8080",
              "agency_did": "VsKV7grR1BUE29mG2Fm2kX",
              "agency_verkey": "Hezce2UWMZ3wUhVkh2LfKSs8nDzWwzs2Win7EzNN3YaR",
              "wallet_name": "alice_wallet",
              "wallet_key": "123",
              "payment_method": "null",
              "enterprise_seed": "000000000000000000000000Trustee1"
            }
            """

        let genesisFilePath = Bundle.main.path(forResource: "genesis", ofType: "txn")

        //Provision an agent and wallet, get back configuration details
        self.cancellable = vcx.agentProvisionAsync(config: provisionConfig)
            .map { config in
                //Set some additional configuration options specific to alice
                var jsonConfigStr = ""
                
                var jsonConfig = try! JSON(data: config.data(using: .utf8)!)
                
                jsonConfig["institution_name"].string = "alice_institute"
                jsonConfig["institution_logo_url"].string = "http://robohash.org/234"
                jsonConfig["genesis_path"].string = genesisFilePath
                
                jsonConfigStr = jsonConfig.rawString()!
                print("Updated json: ", jsonConfigStr)
                
                //Initialize libvcx with a new configuration
                _ = vcx.vcxInitCore(config: jsonConfigStr)
            }
            .flatMap({
                //open pool
                vcx.vcxOpenPool()
            })
            .flatMap({ _ in
                //open wallet
                vcx.vcxOpenWallet()
            })
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }

    @IBAction func btnConnectionRequest(_ sender: UIButton) {
        //Get invitation details from the text box
        let invitation = self.txtInvitation.text!
        
        let vcx = VcxWrapper()
        var connectionHandle = Int()
        var serializedConnection = ""
        
        //Create a connection to faber
        self.cancellable = vcx.connectionCreateWithInvite(invitationId: "1", inviteDetails: invitation)
            .map { handle in
                connectionHandle = handle
            }
            .flatMap({
                vcx.connectionConnect(connectionHandle: connectionHandle, connectionType: "{\"use_public_did\":true}")
            })
            .flatMap({ _ in
                vcx.connectionSerialize(connectionHandle: connectionHandle)
            })
            .map { connection in
                print("Serialized connection: ", connection)
                serializedConnection = connection
            }
            .flatMap({
                vcx.connectionGetPwDid(connectionHandle: connectionHandle)
            })
            .map { pwDid in
                self.did = pwDid
            }
            .flatMap({ _ in
                vcx.addRecordWallet(recordType: "connection", recordId: self.did, recordValue: serializedConnection, tagsJson: "")
            })
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    @IBAction func btnUpdate(_ sender: UIButton) {
        let vcx = VcxWrapper()
        
        let CONNECTION_RESPONSE = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/response"
        let CREDENTIAL_OFFER = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/offer-credential"
        let CREDENTIAL_ISSUED = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/issue-credential"
        let PRESENTATION_REQUEST = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/request-presentation"
        let PRESENTATION_ACK = "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/ack"
        
        var pwDid = did, uid = "", stateUpdateMsg = "", type = ""
        var jsonDecryptedMsg = JSON()
        
        //doenload messages from the agency
        self.cancellable = vcx.downloadMessages(messageStatus: "MS-103", uids: nil, pwdids: pwDid)
            .map { messages in
                print("Downloaded message: ", messages)
                let jsonMessages = try! JSON(data: messages.data(using: .utf8)!)
                
                pwDid = jsonMessages[0]["pairwiseDID"].stringValue
                uid = jsonMessages[0]["msgs"][0]["uid"].stringValue
                stateUpdateMsg = "[{\"pairwiseDID\":\"" + pwDid + "\",\"uids\":[\"" + uid + "\"]}]";
                
                let decryptedMsg = jsonMessages[0]["msgs"][0]["decryptedMsg"].stringValue
                jsonDecryptedMsg = try! JSON(data: decryptedMsg.data(using: .utf8)!)
                
                type = jsonDecryptedMsg["@type"].stringValue
                print("Message type: ", type)
            }
            .flatMap({
                vcx.getRecordWallet(recordType: "connection", recordId: pwDid, optionsJson: "")
            })
            .map { connection in
                let walletRecord = try! JSON(data: connection.data(using: .utf8)!)
                return walletRecord["value"].stringValue
            }
            .flatMap({ connection in
                vcx.connectionDeserialize(serializedConnection: connection)
            })
            .map { handle in
                switch type {
                    case CONNECTION_RESPONSE:
                        self.handleConnection(connectionHandle: handle, pwDid: pwDid)
                    case CREDENTIAL_OFFER:
                        self.handleCredentialOffer(connectionHandle: handle, threadId: jsonDecryptedMsg["@id"].stringValue, stateUpdateMsg: stateUpdateMsg)
                    case CREDENTIAL_ISSUED:
                        self.handleCredential(connectionHandle: handle, threadId: jsonDecryptedMsg["~thread"]["thid"].stringValue)
                    case PRESENTATION_REQUEST:
                        self.handlePresentationRequest(connectionHandle: handle, threadId: jsonDecryptedMsg["@id"].stringValue, stateUpdateMsg: stateUpdateMsg)
                    case PRESENTATION_ACK:
                        self.handleProofResponse(connectionHandle: handle, threadId: jsonDecryptedMsg["~thread"]["thid"].stringValue)
                    default:
                        print("out of scope")
                }
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    func handleConnection (connectionHandle: Int, pwDid: String) {
        print("Handle a connection response")
        
        let vcx = VcxWrapper()

        self.cancellable = vcx.connectionUpdateState(connectionHandle: connectionHandle)
            .flatMap({ _ in
                vcx.connectionSerialize(connectionHandle: connectionHandle)
            })
            .flatMap({ connection in
                vcx.updateRecordWallet(recordType: "connection", recordId: pwDid, recordValue: connection)
            })
            .map { _ in
                //Release vcx objects from memory
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    func handleCredentialOffer (connectionHandle: Int, threadId: String, stateUpdateMsg: String) {
        print("Handle a credential offer")
        
        let vcx = VcxWrapper()
        var credentialHandle = Int()

        //Check agency for a credential offer
        self.cancellable = vcx.credentialGetOffers(connectionHandle: connectionHandle)
            .map { offers in
                print("Credential offers: ", offers)
                //Extranct an offer from string offers
                let jsonOffers = try! JSON(data: offers.data(using: .utf8)!)
                return jsonOffers[0].rawString()!
            }
            .flatMap({ offer in
                //Create a credential object from the credential offer
                vcx.credentialCreateWithOffer(sourceId: "1", credentialOffer: offer)
            })
            .map { handle in
                credentialHandle = handle
            }
            .flatMap({
                //Update a state in the agency
                vcx.updateMessages(messageStatus: "MS-106", magJson: stateUpdateMsg)
            })
            .flatMap({ _ in
                //Send a credential request
                vcx.credentialSendRequest(credentialHandle: credentialHandle, connectionHandle: connectionHandle, paymentHandle: 0)
            })
            .flatMap({ _ in
                vcx.credentialSerialize(credentialHandle: credentialHandle)
            })
            .flatMap({ credential in
                vcx.addRecordWallet(recordType: "credential", recordId: threadId, recordValue: credential, tagsJson: "")
            })
            .map { _ in
                //Release vcx objects from memory
                _ = vcx.credentialRelease(credentialHandle: credentialHandle)
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    func handleCredential(connectionHandle: Int, threadId: String) {
        print("Handle a credential message")
        
        let vcx = VcxWrapper()
        var credentialHandle = Int()

        self.cancellable = vcx.getRecordWallet(recordType: "credential", recordId: threadId, optionsJson: "")
            .map { credential in
                let walletRecord = try! JSON(data: credential.data(using: .utf8)!)
                let serializedCredential = walletRecord["value"].stringValue
                
                return serializedCredential
            }
            .flatMap({ credential in
                vcx.credentialDeserialize(serializedCredential: credential)
            })
            .map { handle in
                credentialHandle = handle
            }
            .flatMap({
                vcx.credentialUpdateState(credentialHandle: credentialHandle, connectionHandle: connectionHandle)
            })
            .map { _ in
                //Release vcx objects from memory
                _ = vcx.credentialRelease(credentialHandle: credentialHandle)
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }

    func handlePresentationRequest(connectionHandle: Int, threadId: String, stateUpdateMsg: String) {
        print("Handle a presentation request")
        
        let vcx = VcxWrapper()
        var proofHandle = Int()

        //Check agency for a proof request
        self.cancellable = vcx.proofGetRequests(connectionHandle: connectionHandle)
            .map { requests in
                print("Requests: ", requests)
                //Extranct a request from string requests
                let jsonRequests = try! JSON(data: requests.data(using: .utf8)!)
                return jsonRequests[0].rawString()!
            }
            .flatMap({ request in
                //Create a Disclosed proof object from proof request
                vcx.proofCreateWithRequest(sourceId: "1", proofRequest: request)
            })
            .map { handle in
                proofHandle = handle
            }
            .flatMap({
                //Update a state in the agency
                vcx.updateMessages(messageStatus: "MS-106", magJson: stateUpdateMsg)
            })
            .flatMap({ _ in
                //Query for credentials in the wallet that satisfy the proof request
                vcx.proofRetrieveCredentials(proofHandle: proofHandle)
            })
            .map { matchingCredentials in
                print("Matching credentials: ", matchingCredentials)

                //Use the first available credentials to satisfy the proof request
                var jsonProofCredentials = try! JSON(data: matchingCredentials.data(using: .utf8)!)
                
                for (key, _):(String, JSON) in jsonProofCredentials["attrs"] {
                    let selectedCredential = jsonProofCredentials["attrs"][key][0]
                    jsonProofCredentials["attrs"][key] = ["credential": selectedCredential]
                }
                
                return jsonProofCredentials.rawString()!
            }
            .flatMap({ selectedCredentials in
                //Generate the proof
                vcx.proofGenerate(proofHandle: proofHandle, selectedCredentials: selectedCredentials, selfAttestedAttrs: "{}")
            })
            .flatMap({ _ in
                //Send the proof
                vcx.proofSend(proofHandle: proofHandle, connectionHandle: connectionHandle)
            })
            .flatMap({ _ in
                vcx.proofSerialize(proofHandle: proofHandle)
            })
            .flatMap({ proof in
                vcx.addRecordWallet(recordType: "proof", recordId: threadId, recordValue: proof, tagsJson: "")
            })
            .map { _ in
                //Release vcx objects from memory
                _ = vcx.proofRelease(proofHandle: proofHandle)
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    func handleProofResponse(connectionHandle: Int, threadId: String) {
        print("Handle a proof response")
        
        let vcx = VcxWrapper()
        var proofHandle = Int()
        
        self.cancellable = vcx.getRecordWallet(recordType: "proof", recordId: threadId, optionsJson: "")
        .map { proof in
            let walletRecord = try! JSON(data: proof.data(using: .utf8)!)
            
            let serializedProof = walletRecord["value"].stringValue
            
            return serializedProof
        }
        .flatMap({ proof in
            vcx.proofDeserialize(serializedProof: proof)
        })
        .map { handle in
            proofHandle = handle
        }
        .flatMap({
            vcx.proofUpdateState(proofHandle: proofHandle, connectionHandle: connectionHandle)
        })
        .map { _ in
            //Release vcx objects from memory
            _ = vcx.proofRelease(proofHandle: proofHandle)
            _ = vcx.connectionRelease(connectionHandle: connectionHandle)
        }
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case .failure(let error): fatalError(error.localizedDescription)
            }
        }, receiveValue: { _ in })
    }
}
