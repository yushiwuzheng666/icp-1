// Persistent logger keeping track of what is going on.
// Length logger should have a bounds of log's count

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Logger "mo:ic-logger/Logger";

actor class LenthyLogger() {

	stable var state : Logger.State<Text> = Logger.new<Text>(0, null);
	let logger = Logger.Logger<Text>(state);

	public shared (msg) func append(msgs: [Text]) {
		logger.append(msgs);
	};

	public query func stats() : async Logger.Stats {
		logger.stats()
	};

	public shared query (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
		logger.view(from, to)
	};
}
