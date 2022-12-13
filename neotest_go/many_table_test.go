package main

import (
	"fmt"
	"net/http"
	"testing"
)

func TestSomeTest(t *testing.T) {
	tt := []struct {
		name   string
		method string
		url    string
		apiKey string
		status int
	}{
		{name: "AccessDenied1", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
		{name: "AccessDenied2", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
		{name: "AccessDenied3", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
		{name: "AccessDenied4", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
		{name: "AccessDenied5", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
		{name: "AccessDenied6", method: http.MethodGet, url: "/api/nothing", apiKey: "lalala", status: http.StatusForbidden},
	}

	for _, tc := range tt {
		tc := tc
		t.Run(tc.name, func(_ *testing.T) {
			fmt.Println(tc.name, tc.method, tc.url, tc.apiKey, tc.status)
		})
	}

}
