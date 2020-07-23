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
    var serializedConnection: String?

    @IBOutlet var txtInvitation: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnProvision(_ sender: UIButton) {
        let vcx = VcxWrapper()

        let provisionConfig = """
            {
              "agency_url": "http://15.165.161.165:8080",
              "agency_did": "VsKV7grR1BUE29mG2Fm2kX",
              "agency_verkey": "Hezce2UWMZ3wUhVkh2LfKSs8nDzWwzs2Win7EzNN3YaR",
              "wallet_name": "alice_wallet",
              "wallet_key": "123",
              "payment_method": "null",
              "enterprise_seed": "000000000000000000000000Trustee1",
              "protocol_type": "4.0"
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

                return jsonConfigStr
            }
            .flatMap({ config in
                //Initialize libvcx with a new configuration
                vcx.initWithConfig(config: config)
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
        
        //Create a connection to faber
        self.cancellable = vcx.connectionCreateWithInvite(invitationId: "1", inviteDetails: invitation)
            .map { handle in
                connectionHandle = handle
            }
            .flatMap({
                vcx.connectionConnect(connectionHandle: connectionHandle, connectionType: "{\"use_public_did\":true}")
            })
            .map { _ in
                sleep(4)
            }
            .flatMap({
                vcx.connectionUpdateState(connectionHandle: connectionHandle)
            })
            .flatMap({ _ in
                vcx.connectionSerialize(connectionHandle: connectionHandle)
            })
            .map { value in
                //Serialize the connection to use in requesting a credential and to present a proof
                self.serializedConnection = value
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    @IBAction func btnAcceptOffer(_ sender: UIButton) {
        let vcx = VcxWrapper()
        var connectionHandle = Int()
        var credentialHandle = Int()
        
        //Deserialize a saved connection
        self.cancellable = vcx.connectionDeserialize(serializedConnection: self.serializedConnection!)
            .map { handle in
                connectionHandle = handle
            }
            .flatMap({
                //Check agency for a credential offers
                vcx.credentialGetOffers(connectionHandle: connectionHandle)
            })
            .map { offers in
                print("Credential offers: ", offers)
                //Extranct an offers from string offers
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
                //Send a credential request
                vcx.credentialSendRequest(credentialHandle: credentialHandle, connectionHandle: connectionHandle, paymentHandle: 0)
            })
            .map { _ in
                //Wait for a while until faber sends a credential
                sleep(4)
            }
            .flatMap({
                //Accept credential offer from faber
                vcx.credentialUpdateState(credentialHandle: credentialHandle)
            })
            .map { _ in
                //Release vcx objects from memory
                _ = vcx.connectionRelease(connectionHandle: connectionHandle)
                _ = vcx.credentialRelease(credentialHandle: credentialHandle)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished: break
                    case .failure(let error): fatalError(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }
    
    @IBAction func btnPresentProof(_ sender: UIButton) {
        let vcx = VcxWrapper()
        var connectionHandle = Int()
        var proofHandle = Int()
        
        //Deserialize a saved connection
        self.cancellable = vcx.connectionDeserialize(serializedConnection: self.serializedConnection!)
        .map { handle in
            connectionHandle = handle
        }
        .flatMap({
            //Check agency for a proof request
            vcx.proofGetRequests(connectionHandle: connectionHandle)
        })
        .map { requests in
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
            //Query for credentials in the wallet that satisfy the proof request
            vcx.proofRetrieveCredentials(proofHandle: proofHandle)
        })
        .map { matchingCredentials in
            print("Credential: ", matchingCredentials)
            
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
        .map { _ in
            //Wait for a while until faber validate a proof and send an ack
            sleep(4)
        }
        .flatMap({
            //Get an ack from faber and finalize the proof process
            vcx.proofUpdateState(proofHandle: proofHandle)
        })
        .map { _ in
            //Release vcx objects from memory
            _ = vcx.connectionRelease(connectionHandle: connectionHandle)
            _ = vcx.proofRelease(proofHandle: proofHandle)
        }
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished: break
                case .failure(let error): fatalError(error.localizedDescription)
            }
        }, receiveValue: { _ in })
    }
}

