import SwiftUI

struct PINEntryView: View {
    let title: String
    let pinLength: Int
    let onComplete: (String) -> Void
    let onBiometric: (() -> Void)?
    let showBiometric: Bool
    @Namespace private var namespace
    
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
        self.pinLength = pinLength
        self.showBiometric = showBiometric
        self.onComplete = onComplete
        self.onBiometric = onBiometric
    }
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.custom("IBMPlexMono-Regular", size: 30))
                    .foregroundStyle(Color(.systemGray2))
            }
            .padding(.top, 60)
            
            // PIN dots
            GlassEffectContainer(spacing: 18) {
                HStack() {
                    ForEach(0..<pin.count, id: \.self) { index in
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 18, height: 18)
                            .glassEffect(.clear.tint(.accent.opacity(0.2)))
                            .glassEffectID(index, in: namespace)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.25), value: pin.count)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: pin.count)
                .frame(height: 18)
            }
            .offset(x: shake ? -10 : 0)
            .animation(shake ? .default.repeatCount(3).speed(6) : .default, value: shake)
            
            // Number pad
            VStack() {
                ForEach(0..<3) { row in
                    HStack(spacing: 0) {
                        ForEach(1...3, id: \.self) { column in
                            let number = row * 3 + column
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 0) {
                    if showBiometric, let onBiometric = onBiometric {
                        Button(action: onBiometric) {
                            Image(systemName: "faceid")
                                .font(.system(size: 30))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    .frame(maxWidth: .infinity)
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 80)
            }
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
                .font(.custom("IBMPlexMono-Medium", size: 30))
                .frame(width: 80, height: 80)
                .foregroundStyle(.foreground)
        }
        //        .buttonSizing(.flexible)
        //        .buttonBorderShape(.circle)
        .glassEffect(.clear.interactive())
        //        .buttonStyle(.glass)
        
    }
}

#Preview {
    PINEntryView(
        title: "Enter PIN",
        showBiometric: true,
        onComplete: { pin in
            print("PIN entered: \(pin)")
        },
        onBiometric: {
            print("Biometric tapped")
        }
    )
}
