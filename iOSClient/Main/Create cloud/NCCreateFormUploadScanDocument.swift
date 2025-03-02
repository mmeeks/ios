//
//  NCCreateFormUploadScanDocument.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/11/2018.
//  Copyright © 2017 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


import Foundation
import WeScan
//import GoogleMobileVision

class NCCreateFormUploadScanDocument: XLFormViewController, NCSelectDelegate {
    
    enum typeDpiQuality {
        case low
        case medium
        case hight
    }
    var dpiQuality: typeDpiQuality = typeDpiQuality.medium
    
    var serverUrl = ""
    var titleServerUrl = ""
    var arrayImages = [UIImage]()
    var fileName = CCUtility.createFileNameDate("scan", extension: "pdf")
    var password: String = ""
    var fileType = "PDF"
    
    //var textDetector: GMVDetector?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    convenience init(serverUrl: String, arrayImages: [UIImage]) {
        
        self.init()
        
        if serverUrl == CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl) {
            titleServerUrl = "/"
        } else {
            titleServerUrl = (serverUrl as NSString).lastPathComponent
        }
        
        self.serverUrl = serverUrl
        self.arrayImages = arrayImages
        
        initializeForm()
    }
    
    //MARK: XLFormDescriptorDelegate
    
    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor(title: NSLocalizedString("_save_settings_", comment: "")) as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))
        
        row.cellConfig["imageView.image"] = CCGraphics.changeThemingColorImage(UIImage(named: "folder")!, width: 50, height: 50, color: NCBrandColor.sharedInstance.brandElement) as UIImage
        
        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: Quality
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_quality_image_title_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "compressionQuality", rowType: XLFormRowDescriptorTypeSlider)
        row.value = 0.5
        row.title = NSLocalizedString("_quality_medium_", comment: "")
        
        row.cellConfig["slider.minimumTrackTintColor"] = NCBrandColor.sharedInstance.brand
        
        row.cellConfig["slider.maximumValue"] = 1
        row.cellConfig["slider.minimumValue"] = 0
        row.cellConfig["steps"] = 2
        
        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.center.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: Password
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_pdf_password_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "password", rowType: XLFormRowDescriptorTypePassword, title: NSLocalizedString("_password_", comment: ""))
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: Text recognition
        
        if NCBrandOptions.sharedInstance.useMLVision {
        
            section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_text_recognition_", comment: ""))
            form.addFormSection(section)
            
            row = XLFormRowDescriptor(tag: "textRecognition", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_text_recognition_", comment: ""))
            row.value = 0
            
            row.cellConfig["imageView.image"] = CCGraphics.changeThemingColorImage(UIImage(named: "textRecognition")!, width: 50, height: 50, color: NCBrandColor.sharedInstance.brandElement) as UIImage
            row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
            
            section.addFormRow(row)
        }
        
        // Section: File
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_file_creation_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "filetype", rowType: XLFormRowDescriptorTypeSelectorSegmentedControl, title: NSLocalizedString("_file_type_", comment: ""))
        
        if arrayImages.count == 1 {
            row.selectorOptions = ["PDF","JPG"]
        } else {
            row.selectorOptions = ["PDF"]
        }
        row.value = "PDF"

        row.cellConfig["tintColor"] = NCBrandColor.sharedInstance.brand
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
            
        section.addFormRow(row)
        
        
        row = XLFormRowDescriptor(tag: "fileName", rowType: XLFormRowDescriptorTypeAccount, title: NSLocalizedString("_filename_", comment: ""))
        row.value = self.fileName
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "textRecognition" {
            
            let rowCompressionQuality: XLFormRowDescriptor = self.form.formRow(withTag: "compressionQuality")!
            let rowFileTape: XLFormRowDescriptor = self.form.formRow(withTag: "filetype")!
            let rowFileName: XLFormRowDescriptor = self.form.formRow(withTag: "fileName")!
            let rowPassword: XLFormRowDescriptor = self.form.formRow(withTag: "password")!
           
            self.form.delegate = nil
            
            if newValue as! Int == 1 {
                rowFileTape.selectorOptions = ["PDF","TXT"]
                rowFileTape.value = "PDF"
                fileType = "PDF"
                rowPassword.disabled = true
                rowCompressionQuality.disabled = true
            } else {
                if arrayImages.count == 1 {
                    rowFileTape.selectorOptions = ["PDF","JPG"]
                } else {
                    rowFileTape.selectorOptions = ["PDF"]
                }
                rowFileTape.value = "PDF"
                fileType = "PDF"
                rowPassword.disabled = false
                rowCompressionQuality.disabled = false
            }
            
            rowFileName.value = createFileName(rowFileName.value as? String)
            self.updateFormRow(rowFileName)
            self.tableView.reloadData()

            self.form.delegate = self
        }
        
        if formRow.tag == "fileName" {
            
            self.form.delegate = nil
            
            let fileNameNew = newValue as? String
            
            if fileNameNew != nil {
                self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew)
            } else {
                self.fileName = ""
            }
            
            formRow.value = self.fileName
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "compressionQuality" {
            
            self.form.delegate = nil
            
            //let row : XLFormRowDescriptor  = self.form.formRow(withTag: "descriptionQuality")!
            let newQuality = newValue as? NSNumber
            let compressionQuality = (newQuality?.doubleValue)!
            
            if compressionQuality >= 0.0 && compressionQuality <= 0.3  {
                formRow.title = NSLocalizedString("_quality_low_", comment: "")
                dpiQuality = typeDpiQuality.low
            } else if compressionQuality > 0.3 && compressionQuality <= 0.6 {
                formRow.title = NSLocalizedString("_quality_medium_", comment: "")
                dpiQuality = typeDpiQuality.medium
            } else if compressionQuality > 0.6 && compressionQuality <= 1.0 {
                formRow.title = NSLocalizedString("_quality_high_", comment: "")
                dpiQuality = typeDpiQuality.hight
            }
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "password" {
            let stringPassword = newValue as? String
            if stringPassword != nil {
                password = stringPassword!
            } else {
                password = ""
            }
        }
        
        if formRow.tag == "filetype" {
            fileType = newValue as! String
            
            let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
            let rowPassword : XLFormRowDescriptor  = self.form.formRow(withTag: "password")!

            rowFileName.value = createFileName(rowFileName.value as? String)
            
            self.updateFormRow(rowFileName)
            
            // rowPassword
            if fileType == "JPG" || fileType == "TXT" {
                rowPassword.value = ""
                password = ""
                rowPassword.disabled = true
            } else {
                rowPassword.disabled = false
            }
        
            self.updateFormRow(rowPassword)
        }
    }
    
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        
        let cell = textField.formDescriptorCell()
        let tag = cell?.rowDescriptor.tag
        
        if tag == "fileName" {
            CCUtility.selectFileName(from: textField)
        }
    }
    
    func createFileName(_ fileName: String?) -> String {
        
        var name: String = ""
        var newFileName: String = ""
        
        if fileName == nil || fileName == "" {
            name = CCUtility.createFileNameDate("scan", extension: "pdf") ?? "scan.pdf"
        } else {
            name = fileName!
        }
        
        let ext = (name as NSString).pathExtension.uppercased()
        
        if (ext == "") {
            newFileName = name + "." + fileType.lowercased()
        } else {
            newFileName = (name as NSString).deletingPathExtension + "." + fileType.lowercased()
        }
        
        return newFileName
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = NCBrandColor.sharedInstance.brand
        self.navigationController?.navigationBar.tintColor = NCBrandColor.sharedInstance.brandText
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: NCBrandColor.sharedInstance.brandText]
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        //        self.tableView.sectionHeaderHeight = 10
        //        self.tableView.sectionFooterHeight = 10
        //        self.tableView.backgroundColor = NCBrandColor.sharedInstance.backgroundView
        
        
        //        let row : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        //        let rowCell = row.cell(forForm: self)
        //        rowCell.becomeFirstResponder()
        
        //textDetector = GMVDetector(ofType: GMVDetectorTypeText, options: nil)
    }
    
    // MARK: - Action
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String) {
        
        if serverUrl != nil {
            
            self.serverUrl = serverUrl!
            
            if serverUrl == CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl) {
                self.titleServerUrl = "/"
            } else {
                self.titleServerUrl = (serverUrl! as NSString).lastPathComponent
            }
            
            // Update
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
            row.title = self.titleServerUrl
            self.updateFormRow(row)
        }
    }
    
    @objc func save() {
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard let name = rowFileName.value else {
            return
        }
        if name as! String == "" {
            return
        }
        
        let ext = (name as! NSString).pathExtension.uppercased()
        var fileNameSave = ""
        
        if (ext == "") {
            fileNameSave = name as! String + "." + fileType.lowercased()
        } else {
            fileNameSave = (name as! NSString).deletingPathExtension + "." + fileType.lowercased()
        }
        
        let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@", appDelegate.activeAccount, self.serverUrl, fileNameSave))
        if (metadata != nil) {
            
            let alertController = UIAlertController(title: fileNameSave, message: NSLocalizedString("_file_already_exists_", comment: ""), preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default) { (action:UIAlertAction) in
            }
            
            let overwriteAction = UIAlertAction(title: NSLocalizedString("_overwrite_", comment: ""), style: .cancel) { (action:UIAlertAction) in
                NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@", self.appDelegate.activeAccount, self.serverUrl, fileNameSave))
                self.dismissAndUpload(fileNameSave, fileID: CCUtility.createMetadataID(fromAccount: self.appDelegate.activeAccount, serverUrl: self.serverUrl, fileNameView: fileNameSave, directory: false)!, serverUrl: self.serverUrl)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(overwriteAction)
            
            self.present(alertController, animated: true, completion:nil)
            
        } else {
            dismissAndUpload(fileNameSave, fileID: CCUtility.createMetadataID(fromAccount: appDelegate.activeAccount, serverUrl: serverUrl, fileNameView: fileNameSave, directory: false)!, serverUrl: serverUrl)
        }
    }
    
    func dismissAndUpload(_ fileNameSave: String, fileID: String, serverUrl: String) {
        
        guard let fileNameGenerateExport = CCUtility.getDirectoryProviderStorageFileID(fileID, fileNameView: fileNameSave) else {
            self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
            return
        }
        
        // Text Recognition TXT
        if fileType == "TXT" && NCBrandOptions.sharedInstance.useMLVision && self.form.formRow(withTag: "textRecognition")!.value as! Int == 1 {
            
            var textFile = ""
            
            for image in self.arrayImages {
                
                /*
                guard let features = self.textDetector?.features(in: image, options: nil) as? [GMVTextBlockFeature] else {
                    continue
                }
                
                for textBlock in features {
                    
                    guard let text = textBlock.value else {
                        continue
                    }
                    
                    textFile = textFile + text + "\n\n"
                }
                */
                
                do {
                    try textFile.write(to: NSURL(fileURLWithPath: fileNameGenerateExport) as URL  , atomically: true, encoding: .utf8)
                } catch {
                    self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                    return
                }
            }
        }
        
        if fileType == "PDF" {
            
            let pdfData = NSMutableData()
            if password.count > 0 {
                let info: [AnyHashable: Any] = [kCGPDFContextUserPassword as String : password, kCGPDFContextOwnerPassword as String : password]
                UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, info)
            } else {
                UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
            }
            let context = UIGraphicsGetCurrentContext()
            
            for var image in self.arrayImages {
                
                if NCBrandOptions.sharedInstance.useMLVision && self.form.formRow(withTag: "textRecognition")!.value as! Int == 1 {
                    
                    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height), nil)
                    UIImageView.init(image:image).layer.render(in: context!)
                    
                    /*
                    if let features = self.textDetector?.features(in: image, options: nil) as? [GMVTextBlockFeature] {
                        for textBlock in features {
                            for textLine in textBlock.lines {
                                
                                let bounds = textLine.bounds
                                let text = textLine.value!
                                var fontColor = UIColor.clear
                                
                                #if targetEnvironment(simulator)
                                fontColor = UIColor.red
                                #endif
                                
                                //print(text)
                                
                                let font = UIFont.systemFont(ofSize: bounds.size.height, weight: .regular)
                                let bestFittingFont = NCUtility.sharedInstance.bestFittingFont(for: text, in: bounds, fontDescriptor: font.fontDescriptor)
                                
                                text.draw(in: bounds, withAttributes: [NSAttributedString.Key.font: bestFittingFont, NSAttributedString.Key.foregroundColor: fontColor])
                            }
                        }
                    }
                    */
                    
                } else {
                    
                    image = changeImageFromQuality(image, dpiQuality: dpiQuality)
                    
                    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height), nil)
                    UIImageView.init(image:image).layer.render(in: context!)
                }
            }
            
            UIGraphicsEndPDFContext();
            
            do {
                try pdfData.write(toFile: fileNameGenerateExport, options: .atomic)
            } catch {
                print("error catched")
            }
        }
        
        if fileType == "JPG" {
            
            let image =  changeImageFromQuality(self.arrayImages[0], dpiQuality: dpiQuality)
            
            guard let data = image.jpegData(compressionQuality: CGFloat(0.5)) else {
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                return
            }
            
            do {
                try data.write(to: NSURL.fileURL(withPath: fileNameGenerateExport), options: .atomic)
            } catch {
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                return
            }
        }
        
        //Create metadata for upload
        let metadataForUpload = tableMetadata()
        
        metadataForUpload.account = self.appDelegate.activeAccount
        metadataForUpload.date = NSDate()
        metadataForUpload.fileID = fileID
        metadataForUpload.fileName = fileNameSave
        metadataForUpload.fileNameView = fileNameSave
        metadataForUpload.serverUrl = serverUrl
        metadataForUpload.session = k_upload_session
        metadataForUpload.sessionSelector = selectorUploadFile
        metadataForUpload.status = Int(k_metadataStatusWaitUpload)
        
        _ = NCManageDatabase.sharedInstance.addMetadata(metadataForUpload)
        NCMainCommon.sharedInstance.reloadDatasource(ServerUrl: self.serverUrl, fileID: nil, action: Int32(k_action_NULL))

        self.appDelegate.startLoadAutoDownloadUpload()
                        
        // Request delete all image scanned
        let alertController = UIAlertController(title: "", message: NSLocalizedString("_delete_all_scanned_images_", comment: ""), preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: NSLocalizedString("_yes_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
            
            let path = CCUtility.getDirectoryScan()!
            
            do {
                let filePaths = try FileManager.default.contentsOfDirectory(atPath: path)
                for filePath in filePaths {
                    try FileManager.default.removeItem(atPath: path + "/" + filePath)
                }
            } catch let error as NSError {
                print("Error: \(error.debugDescription)")
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
        let actionNo = UIAlertAction(title: NSLocalizedString("_no_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(actionYes)
        alertController.addAction(actionNo)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func cancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
        
        self.deselectFormRow(sender)
        
        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        let viewController = navigationController.topViewController as! NCSelect
        
        viewController.delegate = self
        viewController.hideButtonCreateFolder = false
        viewController.includeDirectoryE2EEncryption = true
        viewController.includeImages = false
        viewController.layoutViewSelect = k_layout_view_move
        viewController.selectFile = false
        viewController.titleButtonDone = NSLocalizedString("_select_", comment: "")
        viewController.type = ""
        
        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func changeImageFromQuality(_ image: UIImage, dpiQuality: typeDpiQuality) -> UIImage {
        
        let imageWidthInPixels = image.size.width * image.scale
        let imageHeightInPixels = image.size.height * image.scale
        
        switch dpiQuality {
        case typeDpiQuality.low:                        // 72 DPI
            if imageWidthInPixels > 595 || imageHeightInPixels > 842  {
                return CCGraphics.scale(image, to: CGSize(width: 595, height: 842), isAspectRation: true)
            }
        case typeDpiQuality.medium:                     // 150 DPI
            if imageWidthInPixels > 1240 || imageHeightInPixels > 1754  {
                return CCGraphics.scale(image, to: CGSize(width: 1240, height: 1754), isAspectRation: true)
            }
        case typeDpiQuality.hight:                      // 200 DPI
            if imageWidthInPixels > 1654 || imageHeightInPixels > 2339  {
                return CCGraphics.scale(image, to: CGSize(width: 1654, height: 2339), isAspectRation: true)
            }
        }
        
        return image
    }
}

class NCCreateScanDocument : NSObject, ImageScannerControllerDelegate {
    
    @objc static let sharedInstance: NCCreateScanDocument = {
        let instance = NCCreateScanDocument()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewController: UIViewController?
    var openScan: Bool = false
    
    func openScannerDocument(viewController: UIViewController, openScan: Bool) {
        
        self.viewController = viewController
        self.openScan = openScan
        
        let scannerVC = ImageScannerController()
        scannerVC.imageScannerDelegate = self
        self.viewController?.present(scannerVC, animated: true, completion: nil)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        
        let fileName = CCUtility.createFileName("scan.png", fileDate: Date(), fileType: PHAssetMediaType.image, keyFileName: k_keyFileNameMask, keyFileNameType: k_keyFileNameType, keyFileNameOriginal: k_keyFileNameOriginal)!
        let fileNamePath = CCUtility.getDirectoryScan() + "/" + fileName
        
        // V 1.0
        if (results.doesUserPreferEnhancedImage && results.enhancedImage != nil) {
            do {
                try results.enhancedImage!.pngData()?.write(to: NSURL.fileURL(withPath: fileNamePath), options: .atomic)
            } catch { }
        } else {
            do {
                try results.scannedImage.pngData()?.write(to: NSURL.fileURL(withPath: fileNamePath), options: .atomic)
            } catch { }
        }
    
        // 0.9.1
        /*
        do {
            try results.scannedImage.pngData()?.write(to: NSURL.fileURL(withPath: fileNamePath), options: .atomic)
        } catch { }
        */
        
        scanner.dismiss(animated: true, completion: {
            if (self.openScan) {
                let storyboard = UIStoryboard(name: "Scan", bundle: nil)
                let controller = storyboard.instantiateInitialViewController()!
                
                controller.modalPresentationStyle = UIModalPresentationStyle.pageSheet
                self.viewController?.present(controller, animated: true, completion: nil)
            }
        })
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        appDelegate.messageNotification("_error_", description: error.localizedDescription, visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: Int(k_CCErrorInternalError))
    }
}

