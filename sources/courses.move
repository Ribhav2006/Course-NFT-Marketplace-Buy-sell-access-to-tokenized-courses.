module MyModule::CourseNFTMarketplace {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Struct representing a tokenized course with access control
    struct CourseNFT has store, key {
        course_id: u64,        // Unique identifier for the course
        price: u64,            // Price to purchase access in AptosCoin
        instructor: address,    // Address of the course instructor/creator
        is_active: bool,       // Whether the course is available for purchase
    }

    /// Struct to track user's course access
    struct CourseAccess has store, key {
        owned_courses: vector<u64>,  // List of course IDs the user has access to
    }

    /// Function to create and list a new course NFT for sale
    public fun create_course(
        instructor: &signer, 
        course_id: u64, 
        price: u64
    ) {
        let instructor_addr = signer::address_of(instructor);
        
        // Create the course NFT
        let course_nft = CourseNFT {
            course_id,
            price,
            instructor: instructor_addr,
            is_active: true,
        };
        
        // Store the course NFT under the instructor's account
        move_to(instructor, course_nft);
    }

    /// Function for users to purchase access to a course
    public fun buy_course_access(
        buyer: &signer, 
        instructor_addr: address, 
        course_id: u64
    ) acquires CourseNFT, CourseAccess {
        let buyer_addr = signer::address_of(buyer);
        
        // Get the course details
        let course = borrow_global<CourseNFT>(instructor_addr);
        assert!(course.is_active, 1); // Ensure course is active
        assert!(course.course_id == course_id, 2); // Verify course ID
        
        // Transfer payment from buyer to instructor
        let payment = coin::withdraw<AptosCoin>(buyer, course.price);
        coin::deposit<AptosCoin>(instructor_addr, payment);
        
        // Grant access to the buyer
        if (!exists<CourseAccess>(buyer_addr)) {
            let access = CourseAccess {
                owned_courses: vector::empty<u64>(),
            };
            move_to(buyer, access);
        };
        
        let buyer_access = borrow_global_mut<CourseAccess>(buyer_addr);
        vector::push_back(&mut buyer_access.owned_courses, course_id);
    }
}