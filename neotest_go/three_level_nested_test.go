package main

import "testing"

func TestOdd(t *testing.T) {
	t.Run("odd", func(t *testing.T) {
		t.Run("5 is odd", func(t *testing.T) {
			if 5%2 != 1 {
				t.Error("5 is actually odd")
			}
			t.Run("9 is odd", func(t *testing.T) {
				if 9%2 != 1 {
					t.Error("5 is actually odd")
				}
			})
		})
		t.Run("7 is odd", func(t *testing.T) {
			if 7%2 != 1 {
				t.Error("7 is actually odd")
			}
		})

	})

}
