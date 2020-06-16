//
//  ViewController.swift
//  VcxDemo
//
//  Created by Jeong Kim on 16/06/2020.
//  Copyright © 2020 SK Telecom. All rights reserved.
//

import UIKit
import Combine

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
              "protocol_type": "3.0"
            }
            """

        let genesisFilePath = Bundle.main.path(forResource: "genesis", ofType: "txn")

        self.cancellable = vcx.agentProvisionAsync(config: provisionConfig)
            .map { config in
                var jsonConfigStr = ""

                do {
                    var jsonConfigDic = try JSONDecoder().decode(Dictionary<String, String>.self, from: Data(config.utf8))

                    jsonConfigDic["institution_name"] = "alice_institute"
                    jsonConfigDic["institution_logo_url"] = "http://robohash.org/234"
                    jsonConfigDic["genesis_path"] = genesisFilePath

                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.outputFormatting = .withoutEscapingSlashes

                    let jsonConfigData = try jsonEncoder.encode(jsonConfigDic)
                    jsonConfigStr = String(decoding: jsonConfigData, as: UTF8.self)

                    print("Updated json: ", jsonConfigStr)

                } catch {
                    print(error.localizedDescription)
                }

                return jsonConfigStr
            }.flatMap({ config in
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
        let invitation = self.txtInvitation.text!
        let vcx = VcxWrapper()
        var connectionHandle = Int()
        
        self.cancellable = vcx.connectionCreateWithInvite(invitationId: "1", inviteDetails: invitation)
            .map { handle in
                connectionHandle = handle
            }
            .flatMap({ _ in
                vcx.connectionConnect(connectionHandle: connectionHandle, connectionType: "{\"use_public_did\":true}")
            })
            .map { _ in
                sleep(4)
            }
            .flatMap({ _ in
                vcx.connectionUpdateState(connectionHandle: connectionHandle)
            })
            .flatMap({ _ in
                vcx.connectionSerialize(connectionHandle: connectionHandle)
            })
            .map { value in
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
        
        self.cancellable = vcx.connectionDeserialize(serializedConnection: self.serializedConnection!)
            .map { handle in
                connectionHandle = handle
            }
            .flatMap({ _ in
                vcx.credentialGetOffers(connectionHandle: connectionHandle)
            })
            .map { offers in
                print("Offers: ", offers)

                var jsonOfferStr = ""

                do {
                    let jsonOffersArray = try JSONSerialization.jsonObject(with: Data(offers.utf8), options: []) as? [Any]

                    let jsonOfferData = try JSONSerialization.data(
                        withJSONObject: jsonOffersArray?[0] as Any,
                        options: JSONSerialization.WritingOptions(rawValue: (0)))

                    jsonOfferStr = String(decoding: jsonOfferData, as: UTF8.self)
                    print("Offer: ", jsonOfferStr)
                } catch {
                    print(error.localizedDescription)
                }

                return jsonOfferStr
            }
            .flatMap({ jsonOfferStr in
                vcx.credentialCreateWithOffer(sourceId: "1", credentialOffer: jsonOfferStr)
            })
            .map { handle in
                credentialHandle = handle
            }
            .flatMap({ _ in
                vcx.credentialSendRequest(credentialHandle: credentialHandle, connectionHandle: connectionHandle, paymentHandle: 0)
            })
            .map { _ in
                sleep(4)
            }
            .flatMap({ _ in
                vcx.credentialUpdateState(credentialHandle: credentialHandle)
            })
            .map { _ in
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
        
        self.cancellable = vcx.connectionDeserialize(serializedConnection: self.serializedConnection!)
        .map { handle in
            connectionHandle = handle
        }
        .flatMap({ _ in
            vcx.proofGetRequests(connectionHandle: connectionHandle)
        })
        .map { requests in
            var jsonRequestStr = ""

            do {
                let jsonRequestsArray = try JSONSerialization.jsonObject(with: Data(requests.utf8), options: []) as? [Any]

                let jsonRequestData = try JSONSerialization.data(
                    withJSONObject: jsonRequestsArray?[0] as Any,
                    options: JSONSerialization.WritingOptions(rawValue: (0)))

                jsonRequestStr = String(decoding: jsonRequestData, as: UTF8.self)
                print("Request: ", jsonRequestStr)
            } catch {
                print(error.localizedDescription)
            }
            
            return jsonRequestStr
        }
        .flatMap({ jsonRequestStr in
            vcx.proofCreateWithRequest(sourceId: "1", proofRequest: jsonRequestStr)
        })
        .map { handle in
            proofHandle = handle
        }
        .flatMap({ _ in
            vcx.proofRetrieveCredentials(proofHandle: proofHandle)
        })
        .map { matchingCredentials in
            print("Credential: ", matchingCredentials)
            
            var selectedCredentials = ""
            
            do {
                
               var proofCredentials = try JSONSerialization.jsonObject(with: Data(matchingCredentials.utf8), options: []) as? [String:[String:Any]]

                for attribute in (proofCredentials?["attrs"]!.keys)! {
                    let selectedCredentials = proofCredentials?["attrs"]![attribute] as! [Dictionary<String, Any>]

                    proofCredentials?["attrs"]![attribute] = ["credential": selectedCredentials[0]]
                }
                
                let proofCredentialsData = try JSONSerialization.data(
                    withJSONObject: proofCredentials as Any,
                options: JSONSerialization.WritingOptions(rawValue: (0)))

                selectedCredentials = String(decoding: proofCredentialsData, as: UTF8.self)
                print("Request: ", selectedCredentials)
            } catch {
                print(error.localizedDescription)
            }
            
            return selectedCredentials
        }
        .flatMap({ selectedCredentials in
            vcx.proofGenerate(proofHandle: proofHandle, selectedCredentials: selectedCredentials, selfAttestedAttrs: "{}")
        })
        .flatMap({ _ in
            vcx.proofSend(proofHandle: proofHandle, connectionHandle: connectionHandle)
        })
        .map { _ in
            sleep(4)
        }
        .flatMap({ _ in
            vcx.proofUpdateState(proofHandle: proofHandle)
        })
        .map { _ in
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

