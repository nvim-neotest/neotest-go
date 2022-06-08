//go:build files
// +build files

package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAddOne2(t *testing.T) {
	assert.Equal(t, 2, addOne(1))
}
