use core::array::ArrayTrait;

#[derive(Clone, Debug, Drop, Serde)]
struct Call {
    to: felt252,
    selector: felt252,
    calldata: Span<felt252>,
// context: Span<felt252>, // State needed for the call execution.
}

#[derive(Clone, Debug, Drop, Serde)]
struct Diff {
    key: felt252,
    value: felt252,
// before: felt252, // The `upgrade_state` function could assert that state did not change during commitment.
}


// $ scarb cairo-run "[[1, 1, 2, 0]]"
fn main(input: Array<felt252>) -> Array<felt252> {
    let mut input = input.span();
    let mut calls = Serde::<Array<Call>>::deserialize(ref input).unwrap();

    let mut diffs = array![];

    loop {
        let call = match calls.pop_front() {
            Option::Some(call) => call,
            Option::None => { break; },
        };

        let _contract = *call.calldata.at(1);
        let method = *call.calldata.at(2);

        if method == 138085521528844465635707021766388533460333160809770824619362347246155055131 {
            diffs.append_span(fate_strike(call));
        }
    };

    let mut output = array![];
    diffs.serialize(ref output);
    output
}

fn fate_strike(call: Call) -> Span<Diff> {
    array![Diff { key: 1, value: 2 }].span()
}


#[cfg(test)]
mod tests {
    use super::{main, Call};


    #[test]
    fn flow() {
        let args = array![
            4,
            // register_player
            2443422441049319572448953606800759426118662504379197814235900330513790862105,
            617075754465154585683856897856256838130216341506379215893724690153393808813,
            7,
            1,
            563518697563542123606888854620392365504900406918881341246086066801626937907,
            1259008560618804745770255768445176861078101720763151456759359170279920395577,
            3,
            0,
            469786453359,
            5,
            // enter_dungeons
            2443422441049319572448953606800759426118662504379197814235900330513790862105,
            617075754465154585683856897856256838130216341506379215893724690153393808813,
            4,
            1,
            2290816654334217112471713870648682811963761252797719459477475292900316779618,
            1620375350641424823692909544079593651472683473485402590040799191658387808581,
            0,
            // fate_strike
            2443422441049319572448953606800759426118662504379197814235900330513790862105,
            617075754465154585683856897856256838130216341506379215893724690153393808813,
            4,
            1,
            2290816654334217112471713870648682811963761252797719459477475292900316779618,
            138085521528844465635707021766388533460333160809770824619362347246155055131,
            0,
            // fate_strike
            2443422441049319572448953606800759426118662504379197814235900330513790862105,
            617075754465154585683856897856256838130216341506379215893724690153393808813,
            4,
            1,
            2290816654334217112471713870648682811963761252797719459477475292900316779618,
            138085521528844465635707021766388533460333160809770824619362347246155055131,
            0
        ];

        assert_eq!(main(args).len(), 5);
    }
}

