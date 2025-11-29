import Foundation

enum CIFParserError: Error, LocalizedError {
    case unexpectedEOF(String)
    case unexpectedContext(String)
    case malformedLoop(String)
    
    var errorDescription: String? {
        switch self {
        case .unexpectedEOF(let message):
            return "Unexpected end of file: \(message)"
        case .unexpectedContext(let message):
            return "Unexpected token order: \(message)"
        case .malformedLoop(let message):
            return "Malformed loop: \(message)"
        }
    }
}

struct CIFParser {
    static func parse(from text: String) throws -> CIFFile {
        var tokenizer = CIFTokenizer(text: text)
        var blocks: [CIFDataBlock] = []
        var currentBlock: CIFDataBlock?
        
        while let token = tokenizer.next() {
            let lowered = token.lowercased()
            
            if lowered.hasPrefix("data_") {
                if let block = currentBlock {
                    blocks.append(block)
                }
                let name = String(token.dropFirst(5))
                currentBlock = CIFDataBlock(name: name)
            } else if lowered == "loop_" {
                guard var block = currentBlock else {
                    throw CIFParserError.unexpectedContext("Encountered loop_ before starting a data block.")
                }
                let loop = try parseLoop(using: &tokenizer)
                block.addLoop(loop)
                currentBlock = block
            } else if lowered == "stop_" {
                continue
            } else if token.hasPrefix("_") {
                guard var block = currentBlock else {
                    throw CIFParserError.unexpectedContext("Encountered \(token) before starting a data block.")
                }
                guard let value = tokenizer.next() else {
                    throw CIFParserError.unexpectedEOF("Expected value for tag \(token).")
                }
                block.addItem(tag: token, value: value)
                currentBlock = block
            } else if lowered.hasPrefix("global_") {
                if let block = currentBlock {
                    blocks.append(block)
                }
                let name = String(token.dropFirst(7))
                currentBlock = CIFDataBlock(name: name)
            }
        }
        
        if let block = currentBlock {
            blocks.append(block)
        }
        
        return CIFFile(dataBlocks: blocks)
    }
    
    static func parse(contentsOf url: URL, encoding: String.Encoding = .utf8) throws -> CIFFile {
        let text = try String(contentsOf: url, encoding: encoding)
        return try parse(from: text)
    }
    
    private static func parseLoop(using tokenizer: inout CIFTokenizer) throws -> CIFLoop {
        var headers: [String] = []
        var values: [String] = []
        
        while let token = tokenizer.next() {
            if token.hasPrefix("_") {
                headers.append(token)
            } else {
                values.append(token)
                break
            }
        }
        
        guard !headers.isEmpty else {
            throw CIFParserError.malformedLoop("loop_ must be followed by at least one header.")
        }
        
        guard !values.isEmpty else {
            throw CIFParserError.unexpectedEOF("Loop for headers \(headers.joined(separator: ", ")) is missing values.")
        }
        
        while let token = tokenizer.next() {
            let lowered = token.lowercased()
            let isControl = lowered == "loop_" || lowered == "stop_" || lowered.hasPrefix("data_")
            let isTag = token.hasPrefix("_")
            
            if (isControl || isTag) && values.count % headers.count == 0 {
                tokenizer.pushBack()
                break
            }
            
            values.append(token)
        }
        
        guard values.count % headers.count == 0 else {
            throw CIFParserError.malformedLoop("Values count \(values.count) is not a multiple of header count \(headers.count).")
        }
        
        var rows: [[String]] = []
        for start in stride(from: 0, to: values.count, by: headers.count) {
            let row = Array(values[start..<start + headers.count])
            rows.append(row)
        }
        
        return CIFLoop(headers: headers, rows: rows)
    }
}

struct CIFFile: CustomStringConvertible {
    var dataBlocks: [CIFDataBlock]
    
    var description: String {
        dataBlocks.map { $0.description }.joined(separator: "\n\n")
    }
}

struct CIFDataBlock: CustomStringConvertible {
    let name: String
    private(set) var items: [String: CIFValue] = [:]
    private(set) var itemOrder: [String] = []
    private(set) var loops: [CIFLoop] = []
    
    init(name: String) {
        self.name = name
    }
    
    mutating func addItem(tag: String, value: String) {
        if let existing = items[tag] {
            items[tag] = existing.appending(value)
        } else {
            items[tag] = .single(value)
            itemOrder.append(tag)
        }
    }
    
    mutating func addLoop(_ loop: CIFLoop) {
        loops.append(loop)
    }
    
    func values(for tag: String) -> [String]? {
        items[tag]?.values
    }
    
    var description: String {
        var lines: [String] = ["data_\(name)"]
        for tag in itemOrder {
            if let value = items[tag] {
                lines.append("\(tag) \(value)")
            }
        }
        for loop in loops {
            lines.append(loop.description)
        }
        return lines.joined(separator: "\n")
    }
}

enum CIFValue: CustomStringConvertible {
    case single(String)
    case multiple([String])
    
    var values: [String] {
        switch self {
        case .single(let value):
            return [value]
        case .multiple(let values):
            return values
        }
    }
    
    func appending(_ newValue: String) -> CIFValue {
        switch self {
        case .single(let value):
            return .multiple([value, newValue])
        case .multiple(var values):
            values.append(newValue)
            return .multiple(values)
        }
    }
    
    var description: String {
        switch self {
        case .single(let value):
            return value
        case .multiple(let values):
            return "[" + values.joined(separator: ", ") + "]"
        }
    }
}

struct CIFLoop: CustomStringConvertible {
    let headers: [String]
    let rows: [[String]]
    
    func records() -> [[String: String]] {
        rows.map { row in
            var record: [String: String] = [:]
            for (header, value) in zip(headers, row) {
                record[header] = value
            }
            return record
        }
    }
    
    var description: String {
        var lines: [String] = ["loop_"]
        lines.append(contentsOf: headers)
        for row in rows {
            lines.append(row.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}

private struct CIFTokenizer {
    private let tokens: [String]
    private var index: Int = 0
    
    init(text: String) {
        self.tokens = CIFTokenizer.tokenize(text)
    }
    
    mutating func next() -> String? {
        guard index < tokens.count else { return nil }
        let token = tokens[index]
        index += 1
        return token
    }
    
    mutating func peek() -> String? {
        guard index < tokens.count else { return nil }
        return tokens[index]
    }
    
    mutating func pushBack() {
        guard index > 0 else { return }
        index -= 1
    }
    
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        let characters = Array(text)
        var i = 0
        var atLineStart = true
        
        func isNewline(_ character: Character) -> Bool {
            character == "\n" || character == "\r"
        }
        
        while i < characters.count {
            let character = characters[i]
            
            if character == "#" {
                while i < characters.count && !isNewline(characters[i]) {
                    i += 1
                }
                continue
            }
            
            if character == "\n" {
                atLineStart = true
                i += 1
                continue
            }
            
            if character == "\r" {
                atLineStart = true
                i += 1
                if i < characters.count && characters[i] == "\n" {
                    i += 1
                }
                continue
            }
            
            if character == " " || character == "\t" {
                atLineStart = false
                i += 1
                continue
            }
            
            if character == ";" && atLineStart {
                i += 1
                var value = ""
                var localAtLineStart = true
                while i < characters.count {
                    let current = characters[i]
                    if current == "\n" {
                        value.append(current)
                        i += 1
                        localAtLineStart = true
                        atLineStart = true
                        continue
                    }
                    if current == "\r" {
                        value.append("\n")
                        i += 1
                        if i < characters.count && characters[i] == "\n" {
                            i += 1
                        }
                        localAtLineStart = true
                        atLineStart = true
                        continue
                    }
                    if current == ";" && localAtLineStart {
                        i += 1
                        if value.hasSuffix("\n") {
                            value.removeLast()
                        }
                        tokens.append(value)
                        atLineStart = false
                        break
                    }
                    value.append(current)
                    i += 1
                    localAtLineStart = false
                    atLineStart = false
                }
                continue
            }
            
            if character == "'" || character == "\"" {
                let quote = character
                i += 1
                var value = ""
                while i < characters.count && characters[i] != quote {
                    let current = characters[i]
                    if isNewline(current) {
                        value.append("\n")
                    } else {
                        value.append(current)
                    }
                    i += 1
                }
                if i < characters.count && characters[i] == quote {
                    i += 1
                }
                tokens.append(value)
                atLineStart = false
                continue
            }
            
            var token = ""
            while i < characters.count {
                let current = characters[i]
                if current == " " || current == "\t" || isNewline(current) || current == "#" {
                    break
                }
                token.append(current)
                i += 1
            }
            if !token.isEmpty {
                tokens.append(token)
                atLineStart = false
            }
        }
        
        return tokens
    }
}

extension CIFDataBlock {
    func structure() -> CIFStructure {
        CIFStructure(
            atoms: parseAtoms(),
            bonds: parseBonds()
        )
    }
    
    func loop(containing header: String) -> CIFLoop? {
        loops.first { $0.headers.contains(header) }
    }
    
    private func parseAtoms() -> [CIFAtom] {
        guard let atomLoop = loop(containing: "_chem_comp_atom.atom_id") else {
            return []
        }
        
        return atomLoop.records().map { record in
            CIFAtom(
                componentID: record["_chem_comp_atom.comp_id"] ?? "",
                label: record["_chem_comp_atom.atom_id"] ?? "",
                alternateLabel: Self.sanitized(record["_chem_comp_atom.alt_atom_id"]),
                element: record["_chem_comp_atom.type_symbol"] ?? "",
                charge: Self.parseInt(record["_chem_comp_atom.charge"]),
                x: Self.parseDouble(record["_chem_comp_atom.model_Cartn_x"]),
                y: Self.parseDouble(record["_chem_comp_atom.model_Cartn_y"]),
                z: Self.parseDouble(record["_chem_comp_atom.model_Cartn_z"]),
                idealX: Self.parseDouble(record["_chem_comp_atom.pdbx_model_Cartn_x_ideal"]),
                idealY: Self.parseDouble(record["_chem_comp_atom.pdbx_model_Cartn_y_ideal"]),
                idealZ: Self.parseDouble(record["_chem_comp_atom.pdbx_model_Cartn_z_ideal"]),
                isAromatic: Self.parseFlag(record["_chem_comp_atom.pdbx_aromatic_flag"]) ?? false,
                isBackboneAtom: Self.parseFlag(record["_chem_comp_atom.pdbx_backbone_atom_flag"]) ?? false
            )
        }
    }
    
    private func parseBonds() -> [CIFBond] {
        guard let bondLoop = loop(containing: "_chem_comp_bond.atom_id_1") else {
            return []
        }
        
        return bondLoop.records().map { record in
            CIFBond(
                componentID: record["_chem_comp_bond.comp_id"] ?? "",
                atomID1: record["_chem_comp_bond.atom_id_1"] ?? "",
                atomID2: record["_chem_comp_bond.atom_id_2"] ?? "",
                order: CIFBondOrder(rawValue: Self.sanitized(record["_chem_comp_bond.value_order"]) ?? ""),
                isAromatic: Self.parseFlag(record["_chem_comp_bond.pdbx_aromatic_flag"]) ?? false
            )
        }
    }
    
    private static func sanitized(_ value: String?) -> String? {
        guard let value = value, value != "?" && value != "." else { return nil }
        return value
    }
    
    private static func parseInt(_ value: String?) -> Int? {
        guard let sanitized = sanitized(value) else { return nil }
        return Int(sanitized)
    }
    
    private static func parseDouble(_ value: String?) -> Double? {
        guard let sanitized = sanitized(value) else { return nil }
        return Double(sanitized)
    }
    
    private static func parseFlag(_ value: String?) -> Bool? {
        guard let sanitized = sanitized(value) else { return nil }
        switch sanitized.uppercased() {
        case "Y":
            return true
        case "N":
            return false
        default:
            return nil
        }
    }
}
