package Verification {
    doc /* Root verification package. Verification case definitions live in VER_* packages; aliases preserve Verification::MLLPReceiver etc. for views. */

    alias MLLPReceiver for VER_MLLPReceiver;
    alias Parser for VER_Parser;
    alias Transformer for VER_Transformer;
    alias HTTPForwarder for VER_HTTPForwarder;
    alias ErrorHandler for VER_ErrorHandler;
    alias Adapter for VER_Adapter;
}
