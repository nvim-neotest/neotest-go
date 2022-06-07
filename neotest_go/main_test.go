package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAddOne(t *testing.T) {
	assert.Equal(t, 2, addOne(1))
}

func TestAddTwo(t *testing.T) {
	assert.Equal(t, 3, addTwo(1))
}
