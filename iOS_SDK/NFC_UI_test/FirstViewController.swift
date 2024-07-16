//
//  ViewController.swift
//  NFC_UI_test
//
//  Created by Hanlin on 2023/7/27.
//

import UIKit
import CoreNFC

class FirstViewController: UIViewController,NFCNDEFReaderSessionDelegate {
    
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var ResetButton: UIButton!

    @IBOutlet weak var BottomView: UIView!
    @IBOutlet weak var SecondImage: UIImageView!
    @IBOutlet weak var FirstImage: UIImageView!
    @IBOutlet weak var FirstText1: UILabel!
    @IBOutlet weak var FirstText2: UILabel!
    @IBOutlet weak var FirstText3: UILabel!
    @IBOutlet weak var FirstText4: UILabel!
    @IBOutlet weak var FirstText5: UILabel!
    @IBOutlet weak var SecondText1: UILabel!
    @IBOutlet weak var SecondText2: UILabel!
    
    // Initialize First Background
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        BottomView.layer.cornerRadius = 25
        FirstImage.isHidden = false
        FirstText1.isHidden = false
        FirstText2.isHidden = false
        FirstText3.isHidden = false
        FirstText4.isHidden = false
        FirstText5.isHidden = false
        SecondImage.isHidden = true
        SecondText1.isHidden = true
        SecondText2.isHidden = true
    }
    
    // MARK: - Properties
    
    var message: NFCNDEFMessage = .init(records: [])
    var session: NFCNDEFReaderSession?
    
    // Send NFC Reset Command
    @IBAction func SendResetCommand(_ sender: Any) {
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Searching..."
        // Switch to Second Background
        self.ResetButton.isHidden = true
        FirstImage.isHidden = true
        FirstText1.isHidden = true
        FirstText2.isHidden = true
        FirstText3.isHidden = true
        FirstText4.isHidden = true
        FirstText5.isHidden = true
        SecondImage.isHidden = false
        SecondText1.isHidden = false
        SecondText2.isHidden = false
        // Start NFC
        session?.begin()
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500 milliseconds.
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Try to connect to tag and send NFC message to it.
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate(errorMessage: "Unable to connect to tag.")
                return
            }
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query the status of tag."
                    session.invalidate(errorMessage: "Unable to query the status of tag.")
                    return
                }
                
                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "Tag format is not compatible"
                    session.invalidate(errorMessage: "Tag format is not compatible")
                case .readOnly:
                    session.alertMessage = "Tag is read only."
                    session.invalidate(errorMessage: "Tag is read only.")
                case .readWrite:
                    if session === self.session {
                        if session.delegate === self {
                                let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string:"NFC Reset", locale: Locale(identifier: "en"))
                                let message = NFCNDEFMessage(records: [payload].compactMap { $0 })
                                tag.writeNDEF(message, completionHandler: { (error: Error?) in
                                    if let error = error {
                                        print(error)
                                        session.alertMessage = "Reset Fail"
                                        session.invalidate(errorMessage: "Reset Fail")
                                    } else {
                                        session.alertMessage = "Reset Success"
                                        session.invalidate()
                                    }
                                })
                        } else {
                            session.alertMessage = "Reset Fail"
                            session.invalidate(errorMessage: "Reset Fail")
                        }
                    } else {
                        session.alertMessage = "Reset Fail"
                        session.invalidate(errorMessage: "Reset Fail")
                    }
                @unknown default:
                    session.alertMessage = "Reset Fail"
                    session.invalidate(errorMessage: "Reset Fail")
                }
            })
        })
    }
    
    
    /// - Tag: sessionBecomeActive
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Switch back to First Background
        DispatchQueue.main.async {
            self.ResetButton.isHidden = false
            self.FirstImage.isHidden = false
            self.FirstText1.isHidden = false
            self.FirstText2.isHidden = false
            self.FirstText3.isHidden = false
            self.FirstText4.isHidden = false
            self.FirstText5.isHidden = false
            self.SecondImage.isHidden = true
            self.SecondText1.isHidden = true
            self.SecondText2.isHidden = true
        }
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
            }
        }
    }
}
