import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import Logger "mo:ic-logger/Logger";

import L "LenthyLogger";

actor {
    type Stats = {
        page_size: Nat;
        page: Nat;
        count: Nat;
        offset: Nat;
    };

    // count = PAGE_SIZE * (page - 1) + offset
    var PAGE_SIZE : Nat = 100;
    var page : Nat = 0; // total logger instances count
    var count : Nat = 0; // total log count
    var offset : Nat = 0; // index in current page

    var loggers : Buffer.Buffer<L.LenthyLogger> = Buffer.Buffer<L.LenthyLogger>(0);

    public shared func print_info() : async () {
        if(count > 0) {
            for (i in Iter.range(0, loggers.size() - 1)) {
                Debug.print("logger index:" # Nat.toText(i));
                var logger = loggers.get(i);
                var v : Logger.View<Text> = switch (i + 1 < page) {
                    case (true) { await logger.view(0, PAGE_SIZE - 1) };
                    case (false) { await logger.view(0, count - PAGE_SIZE * (page - 1) - 1) };
                };
                if(v.messages.size() > 0) {
                    for(j in Iter.range(0, v.messages.size() - 1)) {
                        Debug.print(v.messages[j]);
                    };
                };
            };
        };
    };

    func roll_over() : async () {
        if (page == 0 or offset == PAGE_SIZE) {
            let l = await L.LenthyLogger();
            loggers.add(l);
            page := page + 1;
            offset := 0;
        };
    };

    public shared func append(msgs: [Text]) {
        for(msg in msgs.vals()) {
            await roll_over();
            let logger = loggers.get(page - 1);
            logger.append(Array.make(msg));
            count := count + 1;
            offset := offset + 1;
        };
    };

    public query func stats() : async Stats {
        {
            page;
            offset;
            count;
            page_size = PAGE_SIZE;
        }
    };

    // from 0 to 0, means view 1 item
    // from and to is 0 based
    public shared func view(f: Nat, t: Nat) : async [Text] {
        var result : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

        assert(f >= 0 and f <= t and t + 1 <= count);

        if(count > 0) {
            let from = f / PAGE_SIZE;
            Debug.print("start from page:" # Nat.toText(from));
            let to = t / PAGE_SIZE;
            Debug.print("end with page:" # Nat.toText(to));

            for (i in Iter.range(from, to)) {
                Debug.print("process page:" # Nat.toText(i));
                var logger = loggers.get(i);

                let l_from = switch (i == from) {
                    case (true) { f - from * PAGE_SIZE };
                    case (false) { 0 };
                };

                let l_to = switch (i == to) {
                    case (true) { t - to * PAGE_SIZE };
                    case (false) { PAGE_SIZE - 1 };
                };

                var v : Logger.View<Text> = await logger.view(l_from, l_to);

                if(v.messages.size() > 0) {
                    for(j in Iter.range(0, v.messages.size() - 1)) {
                        Debug.print(v.messages[j]);
                        result.add(v.messages[j]);
                    };
                };
            };
        };

        result.toArray()
    };
}
