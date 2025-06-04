fn main(a: pub Field, b: Field) -> pub Field {
    let c = a * b;
    c
}

#[test]
fn test_main() {
    let c = main(3, 5);
    assert(c == 15);

    // Uncomment to make test fail
    // let c = main(1, 1);
    // assert(c == 1);
}
