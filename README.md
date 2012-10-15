Mitt Saldo Library
===================
iOS library for accessing swedish banks, loyalty- and creditcards. Think of it as a specialized screen scraping library. This is the library that power [Mitt Saldo](http://github.com/bjornsallarp/mitt-saldo). By making the interesting bits available as a separate library it will be easier for you to use in your application.

#### Supported banks
* Handelsbanken
* ICABanken
* Ikano bank
* Länsförsäkringar bank
* Nordea
* Svenska Enskilda Banken (SEB)
* Swedbank

#### Supported cards
* Coop
* ICA kortet
* Rikskortet
* Skånetrafiken (Jojo-kort)
* Västtrafiken

Code details
============
MSL (Mitt Saldo Library) use parts of AFNetworking, but not a whole lot. The reason is that in order to support multiple simultanious authenticated requests to the same website cookies need to be handled separate. The cookie implementation used right now is by no means a fully compliant cookie storeage but it does the job needed.

Each service (i.e. bank or card) must have a service description class. The description class describe the service (duh) and provides access to service proxy which does the actual endpoint interaction. A service description class must implement MSLServiceDescriptionProtocol. That way services are discoverable by looking for classes that implement this protocol.

#### Dependencies
* [AFNetworking](http://github.com/AFNetworking/AFNetworking)
* [ILTesting](https://github.com/bjornsallarp/ILTesting)
* [JSONKit](https://github.com/johnezang/JSONKit)


Installation / getting started
==============================
	git clone git@github.com:bjornsallarp/Mitt-Saldo-Library.git
	cd Mitt-Saldo-Library
	git submodule init
	git submodule update

Contribute
==========
Want to contribute some code? Awesome! Currently there's quite a lot of services that lack unit tests but my goal is to catch up on that. If you want to contribute with a service, please make sure you write unit tests as well. I will not accept new services without appropriate tests.

