use v5.40;
use Test2::V0;
use lib '../lib';
use Acme::Bitfield;
#
subtest 'Basic Operations' => sub {
    my $bf = Acme::Bitfield->new( size => 10 );
    is $bf->size,  10, 'Correct size';
    is $bf->count, 0,  'Initially empty';
    $bf->set(0);
    $bf->set(9);
    ok $bf->get(0),  'Bit 0 set';
    ok $bf->get(9),  'Bit 9 set';
    ok !$bf->get(5), 'Bit 5 not set';
    is $bf->count, 2, 'Count is 2';
    $bf->clear(0);
    ok !$bf->get(0), 'Bit 0 cleared';
    is $bf->count, 1, 'Count is 1';
};
subtest 'Bit Ordering (BEP 03)' => sub {
    my $bf = Acme::Bitfield->new( size => 8 );
    $bf->set(0);    # Should be 0x80 in the first byte
    is unpack( 'H*', $bf->data ), '80', 'Index 0 is high bit of first byte';
    $bf->clear(0);
    $bf->set(7);    # Should be 0x01
    is unpack( 'H*', $bf->data ), '01', 'Index 7 is low bit of first byte';
};
subtest 'Fill and Find Missing' => sub {
    my $bf = Acme::Bitfield->new( size => 5 );
    $bf->fill();
    is $bf->count,          5,     'All 5 bits set';
    is $bf->find_missing(), undef, 'No missing bits';
    $bf->clear(2);
    is $bf->find_missing(), 2, 'Found missing bit at index 2';
};
subtest Inverse => sub {
    subtest 'Inverse Method' => sub {
        my $bf = Acme::Bitfield->new( size => 10 );
        $bf->set(0);
        $bf->set(5);
        $bf->set(9);
        is $bf->count, 3, 'Initial count is 3';
        my $inv = $bf->inverse();
        isa_ok $inv, ['Acme::Bitfield'], 'inverse() returns a new Acme::Bitfield';
        is $inv->size,  10, 'Inverted bitfield has same size';
        is $inv->count, 7,  'Inverted bitfield has count 7 (10 - 3)';
        ok !$inv->get(0), 'Bit 0 is now 0';
        ok $inv->get(1),  'Bit 1 is now 1';
        ok !$inv->get(5), 'Bit 5 is now 0';
        ok $inv->get(8),  'Bit 8 is now 1';
        ok !$inv->get(9), 'Bit 9 is now 0';
    };
    subtest 'Inverse of Empty' => sub {
        my $bf  = Acme::Bitfield->new( size => 8 );
        my $inv = $bf->inverse();
        is $inv->count,                8,    'Inverse of empty is full';
        is unpack( 'H*', $inv->data ), 'ff', 'Data is 0xFF';
    };
    subtest 'Inverse of Full' => sub {
        my $bf = Acme::Bitfield->new( size => 8 );
        $bf->fill();
        my $inv = $bf->inverse();
        is $inv->count,                0,    'Inverse of full is empty';
        is unpack( 'H*', $inv->data ), '00', 'Data is 0x00';
    };
    subtest 'Excess Bits remain zero' => sub {
        my $bf  = Acme::Bitfield->new( size => 10 );
        my $inv = $bf->inverse();

        # 10 bits means 2 bytes.
        # Inverted should have 10 bits set to 1.
        # Bits 10-15 should remain 0.
        # Byte 1: 11111111 (0xFF)
        # Byte 2: 11000000 (0xC0 in BEP 03 order)
        is unpack( 'H*', $inv->data ), 'ffc0', 'Excess bits are zeroed out in inverted bitfield';
    };
};
#
done_testing;
