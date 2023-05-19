package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSubtract(t *testing.T) {
	testCases := []struct {
		desc string
		a    int
		b    int
		want int
	}{
		{
			desc: "test one",
			a:    1,
			b:    2,
			want: 3,
		},
		{
			desc: "test two",
			a:    1,
			b:    2,
			want: 7,
		},
	}
	for _, tC := range testCases {
		t.Run(tC.desc, func(t *testing.T) {
			assert.Equal(t, tC.want, subtract(tC.a, tC.b))
		})
	}
}

func TestAdd(t *testing.T) {
	t.Run("test one", func(t *testing.T) {
		assert.Equal(t, 3, add(1, 2))
	})

	t.Run("test two", func(t *testing.T) {
		assert.Equal(t, 5, add(1, 2))
	})

	variable := "string"
	t.Run(variable, func(t *testing.T) {
		assert.Equal(t, 3, add(1, 2))
	})
}

func TestOuter(t *testing.T) {
	testInnerHelper(t)
}

func testInnerHelper(t *testing.T) {
	t.Run("testAddValues", func(t *testing.T) {
		t.Run("testAdd2", func(t *testing.T) {
			testAddValues(t, 1, 2)
		})

		t.Run("testAdd5", func(t *testing.T) {
			testAddValues(t, 0, 5)
		})
	})
}

func testAddValues(t *testing.T, want, num int) {
	assert.Equal(t, want, addOne(num))
}
