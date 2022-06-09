package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDoesAThing(t *testing.T) {
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
			assert.Equal(t, tC.want, doesAThing(tC.a, tC.b))
		})
	}
}

func TestDoesAThingAnotherWay(t *testing.T) {
	t.Run("test one", func(t *testing.T) {
		assert.Equal(t, 3, doesAThing(1, 2))
	})

	t.Run("test two", func(t *testing.T) {
		assert.Equal(t, 5, doesAThing(1, 2))
	})

	variable := "string"
	t.Run(variable, func(t *testing.T) {
		assert.Equal(t, 3, doesAThing(1, 2))
	})
}
