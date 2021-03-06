//
//  DocumentController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class DocumentController: NSDocumentController {
    lazy var accessoryViewController: OpenPanelAccessoryViewController = {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        return storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Open Panel Accessory Controller")) as! OpenPanelAccessoryViewController
    }()

    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?, completionHandler: @escaping (Int) -> Void) {

        openPanel.delegate = accessoryViewController
        openPanel.accessoryView = accessoryViewController.view
        openPanel.isAccessoryViewDisclosed = true

        return super.beginOpenPanel(openPanel, forTypes: types, completionHandler: completionHandler)
    }
    
    override func makeDocument(withContentsOf url: URL, ofType typeName: String) throws -> NSDocument {
        let document = try super.makeDocument(withContentsOf: url, ofType: typeName)
        
        if let document = document as? Document {
            document.offset = accessoryViewController.offset
            document.loadAddress = accessoryViewController.loadAddress
        }
        
        accessoryViewController.reset()
        
        return document
    }
}
