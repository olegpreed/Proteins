import SwiftUI

struct PINEntryView: View {
    let title: String
    let subtitle: String?
    let pinLength: Int
    let onComplete: (String) -> Void
    let onBiometric: (() -> Void)?
    let showBiometric: Bool
    
    @State private var pin: String = ""
    @State private var shake = false
    
    init(
        title: String,
        subtitle: String? = nil,
        pinLength: Int = 4,
        showBiometric: Bool = false,
        onComplete: @escaping (String) -> Void,
        onBiometric: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.pinLength = pinLength
        self.showBiometric = showBiometric
        self.onComplete = onComplete
        self.onBiometric = onBiometric
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 60)
            
            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: shake ? -10 : 0)
            .animation(shake ? .default.repeatCount(3).speed(6) : .default, value: shake)
            
            Spacer()
            
            // Biometric button
            if showBiometric, let onBiometric = onBiometric {
                Button(action: onBiometric) {
                    Image(systemName: "faceid")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
            
            // Number pad
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 15) {
                        ForEach(1...3, id: \.self) { column in
                            let number = row * 3 + column
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }
                
                // Bottom row
                HStack(spacing: 15) {
                    // Empty space
                    Color.clear
                        .frame(width: 80, height: 80)
                    
                    // Zero button
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    
                    // Delete button
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 80, height: 80)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
    
    private func addDigit(_ digit: String) {
        guard pin.count < pinLength else { return }
        pin += digit
        
        if pin.count == pinLength {
            // Small delay before callback for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onComplete(pin)
            }
        }
    }
    
    private func deleteDigit() {
        if !pin.isEmpty {
            pin.removeLast()
        }
    }
    
    func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shake = false
        }
    }
    
    func reset() {
        pin = ""
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    PINEntryView(
        title: "Enter PIN",
        subtitle: "Enter your 4-digit PIN",
        showBiometric: true,
        onComplete: { pin in
            print("PIN entered: \(pin)")
        },
        onBiometric: {
            print("Biometric tapped")
        }
    )
}
