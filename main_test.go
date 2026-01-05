package main

import (
	"bytes"
	"io"
	"os"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func captureStdout(fn func()) string {
	oldStdout := os.Stdout
	r, w, err := os.Pipe()
	Expect(err).NotTo(HaveOccurred())

	os.Stdout = w
	fn()

	Expect(w.Close()).To(Succeed())
	os.Stdout = oldStdout

	var buf bytes.Buffer
	_, err = io.Copy(&buf, r)
	Expect(err).NotTo(HaveOccurred())
	Expect(r.Close()).To(Succeed())

	return buf.String()
}

var _ = Describe("main", func() {
	var originalArgs []string

	BeforeEach(func() {
		originalArgs = os.Args
	})

	AfterEach(func() {
		os.Args = originalArgs
	})

	It("prints the reversed phrase", func() {
		os.Args = []string{"cmd", "hello", "world"}
		output := captureStdout(main)

		Expect(output).To(ContainSubstring("dlrow olleh"))
	})

	It("prints nothing when no args are provided", func() {
		os.Args = []string{"cmd"}
		output := captureStdout(main)

		Expect(output).To(BeEmpty())
	})
})
