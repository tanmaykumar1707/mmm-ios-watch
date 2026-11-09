import WatchConnectivity

/// Singleton that manages all communication with the paired iPhone.
/// iPhone → Watch : receives cards + people via applicationContext.
/// Watch → iPhone : sends new expense via sendMessage.
class PhoneConnector: NSObject, ObservableObject {

    static let shared = PhoneConnector()

    @Published var cards: [WatchCard] = []
    @Published var people: [String] = []
    @Published var sendState: SendState = .idle

    enum SendState: Equatable {
        case idle
        case sending
        case success
        case failure(String)
    }

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send transaction to iPhone

    func sendTransaction(cardId: String, spentFor: String, spentBy: String, amount: Double) {
        guard WCSession.default.isReachable else {
            DispatchQueue.main.async {
                self.sendState = .failure("iPhone not reachable.\nOpen MM app on your phone.")
            }
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        DispatchQueue.main.async { self.sendState = .sending }

        WCSession.default.sendMessage(
            [
                "action":   "addTxn",
                "cardId":   cardId,
                "spentFor": spentFor,
                "spentBy":  spentBy,
                "amount":   amount,
                "date":     formatter.string(from: Date()),
            ],
            replyHandler: { [weak self] _ in
                DispatchQueue.main.async { self?.sendState = .success }
            },
            errorHandler: { [weak self] error in
                DispatchQueue.main.async {
                    self?.sendState = .failure(error.localizedDescription)
                }
            }
        )
    }

    // MARK: - Parse incoming data

    private func apply(_ context: [String: Any]) {
        if let raw = context["cards"] as? [[String: Any]] {
            let parsed: [WatchCard] = raw.compactMap { d in
                guard let id    = d["id"]    as? String,
                      let name  = d["name"]  as? String,
                      let color = d["color"] as? String else { return nil }
                return WatchCard(id: id, name: name, color: color)
            }
            DispatchQueue.main.async { self.cards = parsed }
        }
        if let raw = context["people"] as? [String] {
            DispatchQueue.main.async { self.people = raw }
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnector: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        // Load latest context that arrived while watch was off
        let ctx = session.receivedApplicationContext
        if !ctx.isEmpty { apply(ctx) }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext context: [String: Any]) {
        apply(context)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        apply(message)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        apply(message)
        replyHandler([:])
    }
}
