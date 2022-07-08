open! Async_kernel
module Expect_test_config : Expect_test_config_types.S with type 'a IO.t = 'a Deferred.t
