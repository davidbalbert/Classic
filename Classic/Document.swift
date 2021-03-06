//
//  Document.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    var content = Content()
    var loadAddress: UInt32 {
        get {
            content.loadAddress
        }
        set {
            content.loadAddress = newValue
        }
    }
    var offset: UInt32 {
        get {
            content.offset
        }
        set {
            content.offset = newValue
        }
    }

    override init() {
        super.init()
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)

        if let contentVC = windowController.contentViewController as? AssemblyViewController {
            contentVC.content = content
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        content.read(from: data)
    }
}

