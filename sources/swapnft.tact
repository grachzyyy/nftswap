import "@stdlib/deploy";
import "@stdlib/ownable";

message AdminWithdrawalProfit {
    queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
    queryId: Int as uint64;
}

message AdminFetchProfit {
    queryId: Int as uint64;
}
message OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task5 with Deployable{
    seed: Int = 0;
    owner: Address;
    assets: map<Int, Address>;
    held: Int = 0;
    init(seed: Int, owner: Address) {
        self.assets=emptyMap();
        self.seed=seed;
        self.owner=owner;
    }
    receive(msg: OwnershipAssigned) {
        if(msg.prevOwner==self.owner){
            self.assets.set(self.held, sender());
            self.held = self.held + 1;
            return;
        }
        let nft: Address = sender();
        if(context().value < ton("2.1")){
            send(SendParameters {
                to: nft,
                value:0,
                mode: SendRemainingValue,
                body: Transfer {
                    queryId: msg.queryId,
                    newOwner: msg.prevOwner,
                    responseDestination: msg.prevOwner,
                    customPayload: null,
                    forwardAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell()
            });
            return;
        }
        let rand_idx: Int = randomInt() % (self.held + 1);
        if(rand_idx != self.held){
            nft = self.assets.get(rand_idx)!!;
            self.assets.set(rand_idx,sender());
        }
        send(SendParameters {
            to: nft,
            value: context().value - ton("2.0"),
            mode: SendDefaultMode,
            body: Transfer {
                queryId: msg.queryId,
                newOwner: msg.prevOwner,
                responseDestination: msg.prevOwner,
                customPayload: null,
                forwardAmount: 0,
                forwardPayload: emptySlice(),
            }.toCell()
        });

    }
    receive(msg: AdminWithdrawalProfit) {
        require(sender() == self.owner, "Only for admin");
        nativeReserve(ton("0.1"), 0);
        send(SendParameters {
            to:self.owner,
            value:0,
            mode: SendRemainingBalance,
            body: AdminFetchProfit {queryId: msg.queryId}.toCell()
        });
    }
    receive(msg: AdminWithdrawalAllNFTs) {
        if(sender() != myAddress()){
            require(sender()==self.owner, "invalid sender");
            require(context().value >= ton("1") + ton("0.08") * self.held, "infusufficent funds");
        }
        acceptMessage();
        let mv: Cell = Transfer{queryId:msg.queryId, newOwner:self.owner, responseDestination:self.owner, customPayload:null, forwardAmount:0, forwardPayload:emptySlice()}.toCell();
        repeat(min(100, self.held)) {
            self.held=self.held-1;
            send(SendParameters {
                to:self.assets.get(self.held)!!,
                value: ton("0.02"),
                mode: SendDefaultMode,
                body: mv
            });
        }
        if(self.held>0){
            send(SendParameters {
            to: myAddress(),
            value: 0,
            mode: SendRemainingBalance,
            body: AdminWithdrawalAllNFTs { queryId: msg.queryId }.toCell()
            }); 
        }
        else{
            self.assets = emptyMap();
        }

    }
    get fun profit(): Int {
        return myBalance() - ton("0.1");
    }
    
    get fun nfts(): map<Int, Address> {
        self.assets.set(self.held, null);
        return self.assets;
    }

}
