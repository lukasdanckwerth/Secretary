//
//  SecretaryTests.swift
//  SecretaryTests
//
//  Created by Lukas Danckwerth on 25.08.19.
//  Copyright © 2019 Lukas Danckwerth. All rights reserved.
//

import XCTest
import Secretary

class SecretaryTests: XCTestCase {
   
   override func setUp() {
      // empty
   }
   
   override func tearDown() {
      // empty
   }
   
   
   // ===---------------------------------------------------------------------------------------------------------===
   //
   // MARK: - Simple Test -
   // ===---------------------------------------------------------------------------------------------------------===
   func testShared() {
      XCTAssertEqual(Secretary.shared.label, "com.apple.dt.xctest.tool", "Unexpected label")
   }
   
   
   // ===---------------------------------------------------------------------------------------------------------===
   //
   // MARK: - Simple Print Test -
   // ===---------------------------------------------------------------------------------------------------------===
   func testPrint() {
      
      debug("I'm a debug message")
      info("I'm an info message")
      notice("I'm a noticable message")
      warning("I'm a warning")
      log_error("I'm an error message")
   }
   
   
   // ===---------------------------------------------------------------------------------------------------------===
   //
   // MARK: - Log File Creation -
   // ===---------------------------------------------------------------------------------------------------------===
   func testFileCreation() {
      
      let secretary = Secretary(label: "de.aid.Secretary.File")
      let directoryURL = Secretary.defaultLogsDirectoryURL
      let expectedFileURL = directoryURL.appendingPathComponent("de.aid.Secretary.File.0").appendingPathExtension("log")
      
      secretary.writeFile = true
      XCTAssert(FileManager.default.fileExists(atPath: expectedFileURL.path), "Can't find log file")
      
      secretary.format.printDate = false
      secretary.format.printFileName = false
      secretary.format.printLabel = true
      secretary.format.printLineNumbers = true
      secretary.format.seperator = "|"
      
      secretary.debug("I'm in a file!")
      secretary.notice("Look at me")
      
      do {
         let content = try String(contentsOf: expectedFileURL)
         
         XCTAssertEqual(content, """
            [de.aid.Secretary.File]|[0000]|[    ]|I'm in a file!
            [de.aid.Secretary.File]|[0001]|[NOTE]|Look at me

            """, "Unexpected file content")
         
      } catch {
         XCTFail("Can't read file content")
      }
      
      do {
         try FileManager.default.removeItem(at: expectedFileURL)
      } catch {
         XCTFail("Can't remove created log file")
      }
   }
   
   
   // ===---------------------------------------------------------------------------------------------------------===
   //
   // MARK: - Default Configuration -
   // ===---------------------------------------------------------------------------------------------------------===
   func testDefaultConfiguration() {
      
      let secretary = Secretary(label: "de.aid.Secretary")
      
      XCTAssert(secretary.label == "de.aid.Secretary", "Invalid label '\(secretary.label)'.  Expected 'de.aid.Secretary'")
      XCTAssert(secretary.level == .debug, "Unexpected log `Level`")
      
      XCTAssertNil(secretary.messages, "Unexpected messages collection found")
      XCTAssert(secretary.logLine == 0, "Unexpected amount of entries")
      
      XCTAssert(secretary.format.printLineNumbers == false)
      XCTAssert(secretary.format.printLabel == false)
      XCTAssert(secretary.format.printDate == true)
      XCTAssert(secretary.format.printLevel == true)
      XCTAssert(secretary.format.printFileName == true)
      XCTAssert(secretary.format.lineNumbersFormat == "%04d")
      XCTAssert(secretary.format.seperator ==  "   ")
      XCTAssert(secretary.format.dateFormat == "HH:mm:ss.SSS")
      
      XCTAssert(secretary.writeFile == false)
      
      XCTAssert(secretary.format.maxLineLength == .max)
      // XCTAssert(secretary.maxFileSize == 1024)
      XCTAssert(secretary.maxFileCount == 10, "Unexpected number of max files")
      
      let directoryURL = Secretary.defaultLogsDirectoryURL
      XCTAssert(secretary.directoryPath == directoryURL.path)
   }
   
   
   // ===---------------------------------------------------------------------------------------------------------===
   //
   // MARK: - OSLog Test -
   // ===---------------------------------------------------------------------------------------------------------===
   func testOSLog() {
      
      let secretary = Secretary(label: "de.aid.Secretary")
      secretary.processor = OSLogProcessor(subsystem: secretary.label)
      
      secretary.debug("I'm a debug message")
      secretary.info("I'm an info message")
      secretary.notice("I'm a noticable message")
      secretary.warning("I'm a warning")
      secretary.error("I'm an error message")
      
      XCTAssert(secretary.processor is OSLogProcessor)
   }
}
