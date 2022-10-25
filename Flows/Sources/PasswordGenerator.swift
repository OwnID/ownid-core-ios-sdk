import Foundation

fileprivate struct Gen<A> {
    let run: () -> A
}

fileprivate struct Func<A, B> { let run: (A) -> B }

fileprivate extension Gen {
    func map<B>(_ f: @escaping (A) -> B) -> Gen<B> {
        return Gen<B> { f(self.run()) }
    }
}

fileprivate extension Gen {
    func array(count: Gen<Int>) -> Gen<[A]> {
        return Gen<[A]> {
            Array(repeating: (), count: count.run()).map(self.run)
        }
    }
}

public extension OwnID.FlowsSDK {
    struct Password {
        public init(passwordString: String) {
            self.passwordString = passwordString
        }
        
        public let passwordString: String
        
        public var isValid: Bool {
            passwordString.count > 5
        }
        
        public static func generatePassword(length: UInt = 16) -> Password {
            let passwordLettersSmall = "abcdefghijklmnopqrstuvwxyz"
            let passwordLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            let passwordSpecial = "@$%*&^-+!#_="
            let numbers = "1234567890"
            let passwordChars = passwordLettersSmall + passwordLetters + passwordSpecial + numbers
            
            let alphanum = Gen(run: { passwordChars.randomElement() }).map { $0! }
            let specialNum = Gen(run: { passwordSpecial.randomElement() }).map { $0! }
            
            let passwordSegment = alphanum.array(count: Gen.init { 9 }).map { $0.map{ String($0) }.joined() }
            let passwordGen = passwordSegment.array(count: Gen.init { 6 }).map { $0.joined(separator: "\(specialNum.run())") }
            let passwordObject = Password(passwordString: passwordGen.run())
            return passwordObject
        }
    }
}
