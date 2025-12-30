package main

import (
	"fmt"
	"os"

	cowsay "github.com/Code-Hex/Neo-cowsay"
)

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		return
	}

	input := ""
	for i, word := range args {
		if i > 0 {
			input += " "
		}
		input += word
	}

	runes := []rune(input)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	reversed := string(runes)

	cow, err := cowsay.Say(
		cowsay.Phrase(reversed),
	)
	if err != nil {
		panic(err)
	}

	fmt.Println(cow)
}
