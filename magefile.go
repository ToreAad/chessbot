//go:build mage

package main

import "fmt"

// Creates the binary in the current directory.  It will overwrite any existing
// binary.
func Build() {
	fmt.Println("building!")
}

// Sends the binary to the server.
func Deploy() error {
	return nil
}
