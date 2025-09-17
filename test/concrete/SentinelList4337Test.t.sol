// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import { SentinelList4337Lib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList4337.sol";
import { SentinelListHelper } from "src/SentinelListHelper.sol";

contract SentinelList4337Test is Test {
    using SentinelList4337Lib for SentinelList4337Lib.SentinelList;

    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    SentinelList4337Lib.SentinelList list;
    SentinelList4337Lib.SentinelList newList;
    address account;

    /*//////////////////////////////////////////////////////////////////////////
                                      SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public {
        account = makeAddr("account");

        // only the first list is initialized
        list.init(account);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      UTILS
    //////////////////////////////////////////////////////////////////////////*/

    function addMany(uint256 amount) public {
        for (uint256 i = 1; i <= amount; i++) {
            address addr = makeAddr(vm.toString(i));
            list.push(account, addr);
        }

        for (uint256 i = 1; i <= amount; i++) {
            address addr = makeAddr(vm.toString(i));
            assertTrue(list.contains(account, addr));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_InitRevertWhen_AlreadyInitialized() external {
        // it should revert
        vm.expectRevert();
        list.init(account);
    }

    function test_InitWhenNotInitialized() external {
        // it should set sentinel to sentinel
        address next = list.getNext(account, SENTINEL);
        assertEq(next, SENTINEL);
    }

    function test_AlreadyInitializedWhenSentinelDoesNotPointTo0() external {
        // it should return true
        bool isInitialized = list.alreadyInitialized(account);
        assertTrue(isInitialized);
    }

    function test_AlreadyInitializedWhenSentinelPointsTo0() external {
        // it should return false
        bool isInitialized = newList.alreadyInitialized(account);
        assertFalse(isInitialized);
    }

    function test_GetNextRevertWhen_EntryIsZero() external {
        // it should revert
        vm.expectRevert();
        list.getNext(account, ZERO_ADDRESS);
    }

    function test_GetNextWhenEntryIsNotZero() external {
        // it should return the next entry
        address newEntry = makeAddr("newEntry");
        list.push(account, address(newEntry));

        address next = list.getNext(account, SENTINEL);
        assertEq(next, newEntry);
    }

    function test_PushRevertWhen_EntryIsZero() external {
        // it should revert
        vm.expectRevert();
        list.push(account, ZERO_ADDRESS);
    }

    function test_PushRevertWhen_EntryIsSentinel() external {
        // it should revert
        vm.expectRevert();
        list.push(account, SENTINEL);
    }

    function test_PushRevertWhen_EntryIsAlreadyAdded() external whenEntryIsNotSentinel {
        // it should revert
        address newEntry = makeAddr("newEntry");
        list.push(account, address(newEntry));

        address next = list.getNext(account, SENTINEL);
        assertEq(next, newEntry);

        vm.expectRevert();
        list.push(account, address(newEntry));
    }

    function test_PushWhenEntryIsNotAdded() external whenEntryIsNotSentinel {
        // it should add the entry to the list
        address newEntry = makeAddr("newEntry");
        list.push(account, address(newEntry));
    }

    function test_SafePushWhenListIsNotInitialized() external {
        // it should initialize list
        address newEntry = makeAddr("newEntry");
        newList.safePush(account, newEntry);

        assertTrue(newList.alreadyInitialized(account));
    }

    function test_SafePushRevertWhen_EntryIsZero() external whenListIsInitialized {
        // it should revert
        vm.expectRevert();
        newList.safePush(account, ZERO_ADDRESS);
    }

    function test_SafePushRevertWhen_EntryIsSentinel() external whenListIsInitialized {
        // it should revert
        vm.expectRevert();
        newList.safePush(account, SENTINEL);
    }

    function test_SafePushRevertWhen_EntryIsAlreadyAdded()
        external
        whenListIsInitialized
        whenEntryIsNotSentinel
    {
        // it should revert
        address newEntry = makeAddr("newEntry");
        newList.safePush(account, address(newEntry));

        address next = newList.getNext(account, SENTINEL);
        assertEq(next, newEntry);

        vm.expectRevert();
        newList.safePush(account, address(newEntry));
    }

    function test_SafePushWhenEntryIsNotAdded()
        external
        whenListIsInitialized
        whenEntryIsNotSentinel
    {
        // it should add the entry to the list
        address newEntry = makeAddr("newEntry");
        newList.safePush(account, address(newEntry));
    }

    function test_PopRevertWhen_EntryIsZero() external {
        // it should revert
        vm.expectRevert();
        list.pop(account, SENTINEL, ZERO_ADDRESS);
    }

    function test_PopRevertWhen_EntryIsSentinel() external {
        // it should revert
        vm.expectRevert();
        list.pop(account, SENTINEL, SENTINEL);
    }

    function test_PopRevertWhen_PrevEntryDoesNotPointToEntry() external whenEntryIsNotSentinel {
        // it should revert
        address newEntry = makeAddr("newEntry");

        vm.expectRevert();
        list.pop(account, SENTINEL, address(newEntry));
    }

    function test_PopWhenPrevEntryPointsToEntry() external whenEntryIsNotSentinel {
        // it should remove the entry from the list
        address newEntry = makeAddr("newEntry");
        list.push(account, address(newEntry));

        address next = list.getNext(account, SENTINEL);
        assertEq(next, newEntry);

        list.pop(account, SENTINEL, address(newEntry));

        next = list.getNext(account, SENTINEL);
        assertEq(next, SENTINEL);
    }

    address one = 0x0000000000000000000000000000000000000002;
    address two = 0x0000000000000000000000000000000000000003;
    address three = 0x0000000000000000000000000000000000000004;


    function test_PopAll_PopAllShouldRemoveAllEntries() external {
        // it should remove all entries
        uint256 amount = 8;
        addMany(amount);
        list.popAll(account);

        for (uint256 i = 1; i <= amount; i++) {
            assertFalse(list.contains(account, makeAddr(vm.toString(i))));
        }

        (address[] memory array,) = list.getEntriesPaginated(account, SENTINEL, amount);
        assertEq(array.length, 0);
    }

    // start by testing the popAll on an empty list. Calling popAll on an empty list
    // should set the sentinel back to its init state (one node with a circular reference to itself)
    // a method like popAll should be idempotent 100% of the time.
    function test_PopAll_PopAllOnEmptyListVerifyNextValues() external {
        // after init, the sentinel points to itself
        assertEq(list.getNext(account, SENTINEL), SENTINEL);

        list.popAll(account);

        // assertEq(list.getNext(account, SENTINEL), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, SENTINEL), ZERO_ADDRESS); // ACTUAL
    }

    // this test is similar to the one above, but instead we don't popAll
    // on an empty list but rather a list with a few elements in it.
    function test_PopAll_PushThreeAndPopAllVerifyNextValues() external {
        // after init, the sentinel points to itself. This is correct behaviour.
        assertEq(list.getNext(account, SENTINEL), SENTINEL);

        list.push(account, one);
        list.push(account, two);
        list.push(account, three);

        // This is all correct. The sentinel node points to three, and "one" points to sentinel.
        assertEq(list.getNext(account, SENTINEL), three);
        assertEq(list.getNext(account, three), two);
        assertEq(list.getNext(account, two), one);
        assertEq(list.getNext(account, one), SENTINEL);

        list.popAll(account);

        // assertEq(list.getNext(account, SENTINEL), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, SENTINEL), ZERO_ADDRESS); // ACTUAL
    }

    // similar to the previous test, but we do a popAll first on an empty list
    // and then push three elements to the list. We verify that the behaviour is
    // the same as above: the list ends up with a sentinel node that points to itself
    function test_PopAll_PopAllPushThreeAndVerifyNextValues() external {
        list.popAll(account);

        list.push(account, one);
        list.push(account, two);
        list.push(account, three);

        assertEq(list.getNext(account, SENTINEL), three);
        assertEq(list.getNext(account, three), two);
        assertEq(list.getNext(account, two), one);
        // assertEq(list.getNext(account, SENTINEL), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, SENTINEL), three); // ACTUAL (sentinel node is no longer part of the circle!)
    }

    function test_PopAll_PopAllOnEmptyListCreatesSomeBullshit() external {
        assertEq(list.getNext(account, SENTINEL), SENTINEL);

        list.popAll(account);

        // assertEq(list.getNext(account, SENTINEL), SENTINEL); // failing - points to zero address

        list.push(account, one);
        list.push(account, two);
        list.push(account, three);

        assertEq(list.getNext(account, SENTINEL), three);
        assertEq(list.getNext(account, three), two);
        assertEq(list.getNext(account, two), one);
        // assertEq(list.getNext(account, one), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, one), ZERO_ADDRESS); // ACTUAL

        list.popAll(account);

        (address[] memory array,) = list.getEntriesPaginated(account, SENTINEL, 32);

        // assertEq(array.length, 0); // EXPECTED
        assertEq(array.length, 1); // ACTUAL - should be 0

        // ---- EXPECTED ---- //
        // * we've just called popAll, list should be empty and sentinel in its init state
        // assertEq(list.getNext(account, SENTINEL), SENTINEL);

        // ---- ACTUAL ---- //
        assertEq(list.getNext(account, SENTINEL), three);
        assertEq(list.getNext(account, three), ZERO_ADDRESS);
        assertEq(list.getNext(account, two), ZERO_ADDRESS);
        assertEq(list.getNext(account, one), ZERO_ADDRESS);

        // So what's going on here at this point?
        // * we've just called popAll, yet the list still has a length of 1
        // * the sentinel node is pointing to "three", instead of itself as it should be
        // * "three" is pointing to ZERO_ADDRESS

        list.push(account, three);
        list.push(account, two);
        list.push(account, one);

        // ---- EXPECTED ---- //
        assertEq(list.getNext(account, SENTINEL), one);
        assertEq(list.getNext(account, one), two);
        assertEq(list.getNext(account, two), three);
        // assertEq(list.getNext(account, three), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, three), three); // ACTUAL

        // ---> https://youtu.be/pkKNasQXVV0?si=ticRI6-CHoxaHIwS
        // * "three" is pointing to itself (circular reference)
        // * it has acquired the properties of a sentinel node in an empty list

        (array,) = list.getEntriesPaginated(account, SENTINEL, 32);

        // assertEq(array.length, 3); // EXPECTED
        assertEq(array.length, 32); // ACTUAL

        // * `getEntriesPaginated` goes into a loop due to the circular reference of "three".
        // * It short circuits when it reaches the page size.

        for (uint256 i = 0; i < array.length; i++) {
            console2.log(array[i]);
            if (i == 0) assertEq(array[i], one);
            else if (i == 1) assertEq(array[i], two);
            else assertEq(array[i], three);

            // Log output (32 lines):
            // 0x0000000000000000000000000000000000000002
            // 0x0000000000000000000000000000000000000003
            // 0x0000000000000000000000000000000000000004
            // 0x0000000000000000000000000000000000000004
            // 0x0000000000000000000000000000000000000004
            // 0x0000000000000000000000000000000000000004
            // 0x0000000000000000000000000000000000000004
            // address(4) 26 more times...
        }
    }

    function test_PopAll_PopAllOnEmptyListCreatesSomeMoreBullshit() external {
        list.popAll(account);

        list.push(account, one);
        list.push(account, two);
        list.push(account, three);

        list.popAll(account);

        list.push(account, one);
        list.push(account, two);
        list.push(account, three);

        // by changing the insertion order compared to the previous test,
        // we now get a circular reference between two elements in the list
        // the previous test had a circular reference within the same element

        // ---- EXPECTED ---- //
        // assertEq(list.getNext(account, SENTINEL), three);
        // assertEq(list.getNext(account, one), two);
        // assertEq(list.getNext(account, two), one);
        // assertEq(list.getNext(account, three), SENTINEL);

        // ---- ACTUAL ---- //
        assertEq(list.getNext(account, SENTINEL), three);
        assertEq(list.getNext(account, three), two);
        assertEq(list.getNext(account, two), one);
        assertEq(list.getNext(account, one), three);
        // * "one" points back to "three"
        // * "three" has become the new sentinel node, but ofc the imlementation doesn't understand
        // that
        // * there is no longer any element pointing to the actual sentinel node, so the code has no
        // idea when to terminate
        // * `getEntriesPaginated` will go into a loop finally short circuits when it reaches the
        // page size.

        //     two ------> one
        //      ^        /
        //      |      /
        //      |    /
        //      |  v
        //     three <----- [SENTINEL]

        (address[] memory array,) = list.getEntriesPaginated(account, SENTINEL, 32);

        // assertEq(array.length, 3); // EXPECTED
        assertEq(array.length, 32); // ACTUAL

        for (uint256 i = 0; i < array.length; i++) {
            console2.log(array[i]);

            // (these numbers refer to the indexes at which the corresponding element is found in
            // the list)
            // 0, 3, 6
            // 1, 4, 7
            // 2, 5, 8
            if (i % 3 == 0) assertEq(array[i], three);
            else if (i % 3 == 1) assertEq(array[i], two);
            else assertEq(array[i], one);

            // Log output (32 lines):
            // 0x0000000000000000000000000000000000000004
            // 0x0000000000000000000000000000000000000003
            // 0x0000000000000000000000000000000000000002
            // ... those three lines on a loopy loop...
        }
    }

    function test_PopAll_PopAllShouldSetSentinelToInitState() external {
        // it should set sentinel to zero
        uint256 amount = 8;
        addMany(amount);
        list.popAll(account);

        // assertEq(list.getNext(account, SENTINEL), SENTINEL); // EXPECTED
        assertEq(list.getNext(account, SENTINEL), ZERO_ADDRESS); // ACTUAL
    }

    function test_ContainsWhenEntryIsSentinel() external {
        // it should return false
        bool contains = list.contains(account, SENTINEL);
        assertFalse(contains);
    }

    function test_ContainsWhenEntryIsZero() external whenEntryIsNotSentinel {
        // it should return false
        bool contains = list.contains(account, ZERO_ADDRESS);
        assertFalse(contains);
    }

    function test_ContainsWhenEntryIsNotZero() external whenEntryIsNotSentinel {
        // it should return true
        address newEntry = makeAddr("newEntry");
        list.push(account, address(newEntry));

        bool contains = list.contains(account, address(newEntry));
        assertTrue(contains);
    }

    function test_GetEntriesPaginatedRevertWhen_EntryIsNotContainedOrSentinel() external {
        // it should revert
        vm.expectRevert();
        list.getEntriesPaginated(account, ZERO_ADDRESS, 1);
    }

    function test_GetEntriesPaginatedRevertWhen_PageSizeIsZero()
        external
        whenEntryIsContainedOrSentinel
    {
        // it should revert
        vm.expectRevert();
        list.getEntriesPaginated(account, SENTINEL, 0);
    }

    function test_GetEntriesPaginatedWhenPageSizeIsNotZero()
        external
        whenEntryIsContainedOrSentinel
    {
        // it should return all entries until page size
        // it should return the next entry
        uint256 amount = 8;
        addMany(amount);

        (address[] memory array, address next) = list.getEntriesPaginated(account, SENTINEL, 4);
        assertEq(array.length, 4);
        assertEq(next, makeAddr("5"));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenEntryIsNotSentinel() {
        _;
    }

    modifier whenEntryIsContainedOrSentinel() {
        _;
    }

    modifier whenListIsInitialized() {
        _;
    }
}
