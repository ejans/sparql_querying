Description
===========

A block to query an ontology making use of the [Redland] libraries.
This version is to be used with the dev branch of microblx.

Instructions
============

View the [wiki] for installing instructions.

Overview
========

Internals
---------

![][Blocks]

Layout of the query example.

![][ontology_schema]

The purpose of this block is to query an ontology (local or on the internet) and to feed the gathered data to a _filter_.
This filter block is able to get specific configuration parameters from the gathered data.

Use case
--------

We have a tomato somewhere of a specific type (e.g. roma), we would like to check if the size of this tomato is inside the "range" of our roma tomato model.

1. A _checker_ block creates a query and passes this to the configuration of the _sparql qyeryer_ block
2. A _convertor/filter_ block converts and filters the result of this query to be usable for the _checker_ block
3. The _checker_ can check if the size is in range

License
=======

This software is published under a dual-license: GNU Lesser General Public License LGPL 2.1 and BSD license. The dual-license implies that users of this code may choose which terms they prefer.

Acknowledgment
==============

The research leading to these results has received funding from the 
European Community's Seventh Framework Programme under grant 
agreement no. FP7-600958 (SHERPA: Smart collaboration between Humans and
ground-aErial Robots for imProving rescuing activities in Alpine
environments)

Task List
=========

- [ ] Internal iblocks
- [ ] Bring configuration outside
- [ ] Different representations of result --> config
- [ ] Filter block in separate [repo]
- [ ] Separate the _datatype_ we are going to query (e.g. hdf5, netcdf, rdf, ...) with the _transport protocol_ (http, local, ethercat, ...) so we can add middleware into the communication specific parts. --> queryer block with smaller blocks inside --> Possible to separate with redland lib?

[Redland]: http://www.librdf.org
[wiki]: https://www.github.com/ejans/sparql_querying/wiki
[Blocks]: figs/Blocks.png?raw=true
[ontology_schema]: figs/Ontology_Schema.png?raw=true
[repo]: https://www.github.com/ejans/filtering
