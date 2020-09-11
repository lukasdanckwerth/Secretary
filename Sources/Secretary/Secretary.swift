//
//  Secretary.swift
//  Secretary
//
//  Created by Lukas Danckwerth on 25.08.19.
//  Copyright © 2017 Lukas Danckwerth. All rights reserved.
//

import Foundation
import os.log



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - OutputProcessor -
// ===---------------------------------------------------------------------------------------------------------===
public protocol OutputProcessor {
   
   
   /// This method is called when a `LogProcessor` must emit a log message. There is no need for the `LogProcessor` to
   /// check if the `level` is above or below the configured `logLevel` as `Secretary` already performed this check and
   /// determined that a message should be logged.
   ///
   /// - parameters:
   ///     - message: The message to log.
   mutating func write(_ message: String)
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - `Secretary` -
// ===---------------------------------------------------------------------------------------------------------===
public class Secretary {
   
   
   // MARK: - Properties
   
   /// An identifier of the creator of this `Secretary`.
   open var label: String {
      didSet { precondition(label.trimmingCharacters(in: .whitespaces).count > 0,
                            "Invalid label name (\"\(label)\").  Name must not be empty") }
   }
   
   /// The servertiy of logging.  Default is `.debug` for debugging and `.info` for release.
   open var level: Level
   
   /// The `OutputProcessor` which prints the log messages to a output.
   open var processor: OutputProcessor
   
   /// The `OutputFormat` that creates beautifully string messages from log events.
   open var format: OutputFormat
   
   
   
   /// An in memory collection of all messages.  Default is `nil`.
   private(set) open var messages: [String]? = nil
   
   /// Counts the number of log requests.
   private(set) open var logLine: Int = 0
   
   
   
   // MARK: - Configuration
   
   /// A Boolean value indicating whether to write log messages to a file.  Default is `false`.
   open var writeFile = false {
      didSet { if oldValue != writeFile { writeFileDidChange() }}
   }
   
   
   /// The max size a log file can be in Kilobytes. Default is 1024 (1 MB)
   // public var maxFileSize: UInt64 = 1024
   
   /// The max number of log file that will be stored.  Once this point is reached, the oldest file is deleted.  Default is `10`.
   open var maxFileCount = 10
   
   
   
   
   
   // MARK: - File Pathes
   
   /// The path to the logs directory.
   open var directoryPath: String = Secretary.defaultLogsDirectoryURL.path
   
   
   // MARK: - Initialization
   
   /// Construct a `Secretary` given a `label` identifying the creator of the `Secretary`.
   ///
   /// The `label` should identify the creator of the `Secretary`. This can be an application, a sub-system, or even
   /// a datatype.
   ///
   /// - parameters:
   ///     - label: An identifier for the creator of a `Secretary`.
   ///     - processor: A `LogProcessor` that writes the log messages to a medium.
   fileprivate init(label: String, format: OutputFormat, processor: OutputProcessor) {
      self.label = label
      self.format = format
      self.processor = processor
      #if DEBUG
      self.level = .debug
      #else
      self.level = .info
      #endif
   }
}


// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - `Secretary` Statics -
// ===---------------------------------------------------------------------------------------------------------===
extension Secretary {
   
   
   // MARK: - Global shared Instance
   
   /// Default shared `Secretary` instance.
   public static var shared: Secretary = Secretary(label: Bundle.main.bundleIdentifier ?? "Secretary")
   
   
   // MARK: - Log Directories
   
   /// The `URL` of the users library directory.
   private static let libraryDirectoryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
   
   /// The `URL` of the users document directory.
   private static let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
   
   
   /// Returns the `URL` of the default log directory.
   ///
   /// For iOS this will be: `.../Documents/Logs/`
   ///
   /// On macOS this will be: `.../Library/Logs/`
   ///
   public static var defaultLogsDirectoryURL: URL {
      
      #if os(macOS)
      let directoryURL = libraryDirectoryURL.appendingPathComponent("Logs", isDirectory: true)
      #elseif os(iOS)
      let directoryURL = documentDirectoryURL.appendingPathComponent("Logs", isDirectory: true)
      #endif
      
      let fileManager = FileManager.default
      if !directoryURL.path.isEmpty && !fileManager.fileExists(atPath: directoryURL.path)  {
         do {
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
         } catch {
            NSLog("Can't create directory at '\(directoryURL.path)'.  \(error)")
         }
      }
      
      return directoryURL
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - `Secretary` Initialization -
// ===---------------------------------------------------------------------------------------------------------===
extension Secretary {
   
   
   /// Construct a `Secretary` given a `label` identifying the creator of the `Secretary`.
   ///
   /// - parameters:
   ///     - label: An identifier for the creator of a `Secretary`.
   public convenience init(label: String) {
      self.init(label: label, format: OutputFormat(), processor: StreamProcessor.standardOutput)
   }
   
   
   /// Construct a `Secretary` given a `label` identifying the creator of the `Secretary`.
   ///
   /// - parameters:
   ///     - label: An identifier for the creator of a `Secretary`.
   ///     - directoryPath: A path to the log directory.
   public convenience init(label: String, directoryPath: String) {
      self.init(label: label, format: OutputFormat(), processor: StreamProcessor.standardOutput)
      self.directoryPath = directoryPath
      self.writeFile = true
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Functions -
// ===---------------------------------------------------------------------------------------------------------===
extension Secretary {
   
   
   /// Tells the receiver that the value of the `writeFile` did change.
   internal func writeFileDidChange() {
      
      if writeFile {
         let directoryPath = Secretary.defaultLogsDirectoryURL.path
         do {
            processor = try FileProcessor(directoryPath: directoryPath, name: label, maxFileCount: maxFileCount)
         } catch {
            NSLog("Can't create `FileProcessor` at '\(directoryPath)'.  \(error)")
         }
      } else {
         processor = StreamProcessor.standardOutput
      }
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Log Functions -
// ===---------------------------------------------------------------------------------------------------------===
extension Secretary {
   
   public func debug(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
      internalLog(file: file, function: function, line: line, column: column, level: .debug, more, throwable: nil)
   }
   
   public func info(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
      internalLog(file: file, function: function, line: line, column: column, level: .info, more, throwable: nil)
   }
   
   public func notice(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
      internalLog(file: file, function: function, line: line, column: column, level: .notice, more, throwable: nil)
   }
   
   public func warning(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
      internalLog(file: file, function: function, line: line, column: column, level: .warning, more, throwable: nil)
   }
   
   public func error(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?..., throwable: Error? = nil) {
      internalLog(file: file, function: function, line: line, column: column, level: .error, more, throwable: throwable)
   }
   
   
   // MAKR: - Internal Log Functions
   
   fileprivate func internalLog(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, level: Level, _ array: [Any?], throwable: Error?) {
      
      // guard the log serverity fits
      guard level >= self.level else { return }
      
      // ask output formatter to create a sting from given arguments
      let message = format.string(from: label, logLine: logLine, file: file, function: function, line: line, column: column, level: level, array, throwable: throwable)
      
      // increase the number of logged messages
      logLine += 1
      
      // write message to processor
      processor.write("\(message)\n")
      
      // append message to in memory collection
      messages?.append(message)
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Level -
// ===---------------------------------------------------------------------------------------------------------===
extension Secretary {
   
   /// The log level.
   ///
   /// Log levels are ordered by their severity, with `.debug` being the least severe and
   /// `.critical` being the most severe.
   public enum Level: Int, CustomStringConvertible, Comparable {
      
      /// Appropriate for messages that contain information normally of use only when debugging a program.
      case debug = 0
      
      /// Appropriate for informational messages.
      case info = 10
      
      /// Appropriate for conditions that are not error conditions, but that may require special handling.
      case notice = 20
      
      /// Appropriate for messages that are not error conditions, but more severe than `.notice`.
      case warning = 30
      
      /// Appropriate for error conditions.
      case error = 40
      
      
      // MARK: - CustomStringConvertible
      
      public var description: String {
         switch self {
         case .debug:
            return "    "
         case .info:
            return "INFO"
         case .notice:
            return "NOTE"
         case .warning:
            return "WARN"
         case .error:
            return "ERRR"
         }
      }
      
      
      // MARK: - Level + Comparable
      
      public static func < (lhs: Secretary.Level, rhs: Secretary.Level) -> Bool {
         return lhs.rawValue < rhs.rawValue
      }
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - OutputFormat -
// ===---------------------------------------------------------------------------------------------------------===
open class OutputFormat {
   
   
   // MARK: - Configuration
   
   /// A Boolean value indicating whether to print line numbers.  Default is `false`.
   public var printLineNumbers = false
   
   /// A Boolean value indicating whether to print the label of the Secretary.  Default is `false`.
   public var printLabel = false
   
   /// A Boolean value indicating whether to include the date in a log message.  Default is `true`.
   public var printDate = true
   
   /// A Boolean value indicating whether to include the `Level` in a log message.  Default is `true`.
   public var printLevel = true
   
   /// A Boolean value indicating whether to include the file in a log message.  Default is `true`.
   public var printFileName = true
   
   
   /// Defines the max length of a line before it is trimmed.  Default is `Int.max`.
   public var maxLineLength: Int = .max
   
   /// The format of the line numbers.  Default is `"%04d"`.
   public var lineNumbersFormat = "%04d"
   
   /// Seprator for log messages.  Default is `"   "`.
   public var seperator: String? = "   "
   
   /// Date format.  Default is `"HH:mm:ss.SSS"`.
   public var dateFormat: String! {
      get { return dateFormatter.dateFormat }
      set { dateFormatter.dateFormat = newValue }
   }
   
   /// Date formatter.
   public lazy var dateFormatter: DateFormatter = {
      let f = DateFormatter()
      f.dateFormat = "HH:mm:ss.SSS"
      return f
   }()
   
   /// Returns the stripped file name of a Swift file path.
   public func sourceFileName(filePath: String) -> String {
      return filePath.components(separatedBy: "/").last?.replacingOccurrences(of: ".swift", with: "") ?? ""
   }
   
   
   // MARK: - Implement OutputFormatter
   
   public func string(from label: String, logLine: Int, file: String, function: String, line: Int, column: Int, level: Secretary.Level, _ array: [Any?], throwable: Error?) -> String {
      
      // use collection for parts of the message
      var components = [String]()
      
      if printLabel        { components.append("[\(label)]") }
      if printLineNumbers  { components.append("[\(String(format: lineNumbersFormat, logLine))]") }
      if printDate         { components.append(dateFormatter.string(from: Date())) }
      if printLevel        { components.append("[\(level)]") }
      if printFileName     { components.append("[\(sourceFileName(filePath: file)) \(line):\(column)]") }
      
      // combine the arguments given in `array`
      let strMore = array.compactMap({ $0 }).compactMap({ "\($0)" }).joined(separator: " ")
      components.append(strMore)
      
      // check error
      if let throwable = throwable {
         components.append("\(throwable)".replacingOccurrences(of: "\n", with: " ").condenseWhitespace)
      }
      
      // build message
      var message = components.joined(separator: seperator ?? " ")
      
      // check whether the message reached the max line length
      if message.count > maxLineLength {
         message = message[..<(message.index(message.startIndex, offsetBy: maxLineLength))] + "..."
      }
      
      return message
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - `StreamProcessor` -
// ===---------------------------------------------------------------------------------------------------------===

/// `StreamProcessor` is a simple implementation of `LogProcessor` for directing
/// `Secretary` output to either `stderr` or `stdout` via the factory methods.
public struct StreamProcessor: OutputProcessor {
   
   
   // MARK: - Statics
   
   /// Factory that makes a `StreamProcessor` to directs its output to `stdout`.
   public static var standardOutput: OutputProcessor {
      return StreamProcessor(stream: StdioOutputStream.stdout)
   }
   
   /// Factory that makes a `StreamProcessor` to directs its output to `stderr`.
   public static var standardError: OutputProcessor {
      return StreamProcessor(stream: StdioOutputStream.stderr)
   }
   
   
   // MARK: - Properties
   
   /// The text output stream of this processor.
   internal var stream: TextOutputStream
   
   
   // MARK: - Implement `LogProcessor`
   
   public mutating func write(_ message: String) {
      self.stream.write(message)
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - `FileProcessor` -
// ===---------------------------------------------------------------------------------------------------------===

/// `FileProcessor` is a simple implementation of `OutputProcessor` for directing `Secretary` output to a file.
public struct FileProcessor: OutputProcessor {
   
   
   // MARK: - Properties
   
   /// The path to the directory of the logfile.
   private var directoryPath: String
   
   /// The name of the logfile.
   private var name: String
   
   /// The maximum number of stored logfiles.
   private var maxFileCount: Int
   
   /// The path to the log file in the log directory.
   public var filePath: String { return "\(directoryPath)/\(fileName(0))" }
   
   
   // MARK: - Initialization
   
   /// Creates file if not existing.
   init(directoryPath: String, name: String, maxFileCount: Int) throws {
      self.directoryPath = directoryPath
      self.name = name
      self.maxFileCount = maxFileCount
      if !FileManager.default.fileExists(atPath: filePath) {
         try "".write(toFile: filePath, atomically: true, encoding: .utf8)
      }
   }
   
   
   // MARK: - Implement `LogProcessor`
   
   public mutating func write(_ message: String) {
      guard let handle = FileHandle(forWritingAtPath: filePath) else {
         return NSLog("Can't create file handle for file at '\(filePath)'")
      }
      handle.seekToEndOfFile()
      handle.write(message.data(using: .utf8)!)
      handle.closeFile()
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Extension FileProcessor -
// ===---------------------------------------------------------------------------------------------------------===
extension FileProcessor {
   
   fileprivate func shiftFiles() {
      
      // receive file path
      let path = filePath
      
      // receive default file manager
      let fileManager = FileManager.default
      
      // only rename files if first file exists and isn't empty
      guard fileManager.fileExists(atPath: path), fileSize(path) > 0 else { return }
      
      // recursively rename log files
      rename(0)
      
      // delete the oldest file
      let oldestFilePath = "\(directoryPath)/\(fileName(maxFileCount))"
      
      // break if we have no oldest file
      guard fileManager.fileExists(atPath: oldestFilePath) else { return }
      
      do {
         try fileManager.removeItem(atPath: oldestFilePath)
      } catch {
         NSLog("Can't remove item '\(oldestFilePath)'. \(error)")
      }
   }
   
   /// Recursive method call to rename log files
   private func rename(_ index: Int) {
      
      let curPath = "\(directoryPath)/\(fileName(index))"
      let newPath = "\(directoryPath)/\(fileName(index + 1))"
      
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: newPath) {
         rename(index + 1)
      }
      
      do {
         try fileManager.moveItem(atPath: curPath, toPath: newPath)
      } catch {
         NSLog("Can't move item '\(curPath)' to '\(newPath)'. \(error)")
      }
   }
   
   /// Returns the name of the log file with the given index.
   private func fileName(_ index :Int) -> String {
      return "\(name).\(index).log"
   }
   
   /// Returns the size of the file at the given path.
   private func fileSize(_ path: String) -> UInt64 {
      let fileManager = FileManager.default
      let attributes: NSDictionary? = try? fileManager.attributesOfItem(atPath: path) as NSDictionary
      if let dict = attributes { return dict.fileSize() }
      return 0
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - OSLogProcessor -
// ===---------------------------------------------------------------------------------------------------------===
@available(OSX 10.12, *)
public struct OSLogProcessor: OutputProcessor {
   
   
   // MARK: - Properties
   
   /// The `OSLog` object for logging.
   public let osLog: OSLog
   
   
   // MARK: - Initialization
   
   /// Creates a new instance from the given arguments.
   public init(subsystem: String) {
      osLog = OSLog(subsystem: subsystem, category: /* ignore category for now */ "")
   }
   
   
   // MARK: - Implement `LogProcessor`
   
   public mutating func write(_ message: String) {
      os_log("%{PUBLIC}@", log: osLog, type: OSLogType.info, message)
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - StdioOutputStream -
// ===---------------------------------------------------------------------------------------------------------===

// Prevent name clashes
#if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
let systemStderr = Darwin.stderr
let systemStdout = Darwin.stdout
#else
let systemStderr = Glibc.stderr!
let systemStdout = Glibc.stdout!
#endif

/// A wrapper to facilitate `print`-ing to stderr and stdio that
/// ensures access to the underlying `FILE` is locked to prevent
/// cross-thread interleaving of output.
internal struct StdioOutputStream: TextOutputStream {
   
   
   // MARK: - Properties
   
   internal let file: UnsafeMutablePointer<FILE>
   internal let flushMode: FlushMode
   
   internal func write(_ string: String) {
      string.withCString { ptr in
         flockfile(self.file)
         defer {
            funlockfile(self.file)
         }
         _ = fputs(ptr, self.file)
         if case .always = self.flushMode {
            self.flush()
         }
      }
   }
   
   /// Flush the underlying stream.
   /// This has no effect when using the `.always` flush mode, which is the default
   internal func flush() {
      _ = fflush(self.file)
   }
   
   
   // MARK: - Statics
   
   internal static let stderr = StdioOutputStream(file: systemStderr, flushMode: .always)
   internal static let stdout = StdioOutputStream(file: systemStdout, flushMode: .always)
   
   
   // MARK: - `FlushMode`
   
   /// Defines the flushing strategy for the underlying stream.
   internal enum FlushMode {
      case undefined
      case always
   }
}



// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Global Log Functions -
// ===---------------------------------------------------------------------------------------------------------===
public func debug(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .debug, more, throwable: nil)
}

public func info(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .info, more, throwable: nil)
}

public func notice(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .notice, more, throwable: nil)
}

public func warning(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .warning, more, throwable: nil)
}

public func log_error(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?..., throwable: Error? = nil) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .error, more, throwable: throwable)
}

// convenient
public func verbose(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, _ more: Any?...) {
   Secretary.shared.internalLog(file: file, function: function, line: line, column: column, level: .debug, more, throwable: nil)
}


// ===---------------------------------------------------------------------------------------------------------===
//
// MARK: - Internal String Extension -
// ===---------------------------------------------------------------------------------------------------------===
private extension String {
   
   /// Returns a new string variation where all multiple occurences of whitespaces are replaced by one whitespace.
   var condenseWhitespace: String {
      return self.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
   }
}

// MARK: - Convenience Log Functions -

extension Secretary {
   
   public func prettyPrint<Type>(value: Type) where Type: Codable {
      let jsonEncoder = JSONEncoder()
      jsonEncoder.outputFormatting = .prettyPrinted
      do {
         let data = try jsonEncoder.encode(value)
         print("\n\n\(String(data: data, encoding: .utf8) ?? "")\n\n")
      } catch {
         print("Can't encode \(value)")
      }
   }
}
