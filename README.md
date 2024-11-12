# Roadway

| *Productivity desktop tool that manages project plans.*

A project plan's **assets** are the files, websites, images, documents we collect and produce to guide a project. They are found in many locations on your computers and in the cloud. 

Traditionally, the assets of a project plan imply their relationships to each other using:
* name
* location or path (URI hierarchy)
* metadata (in sidecar files or embedded)

The assets are renamed, tagged, modified and moved in order to move forward with a project. Every change to any of these assets constitutes a new version of the project.

Every change -- simply renaming one -- will break the relationships between assets.

Other problems:

(1) in structural cases:
* there are subprojects (which we will simply call a *project with relations*)
* projects can share common assets
* the folder structures are mirrored in file pathways within the assets, contributing to breakage
* mirrors of the project, typically as backups, but also for work sharing are not easily merged or compared

(2) in evolutionary cases:
* names get stale
* locations within organizational folders get stale, or worse, multiple locations are necessary to represent one-to-many attributes (see tagging)

(3) attributes
* incorrect tagging (spelling errors)
* semantic duplication in tags
* unnecessarily traits
* useless traits

**Roadway** can be thought of as a *bookmark organizer*, but with a few extra features:
* it **ingests** assets from multiple convenient places:
    * the file system
    * the clipboard
    * your browser
    * the cloud
* you can **view, edit** some of these
* you can make "file"-like objects that don't live on a file system
* you **relate** assets to each other
* you can **attach** notes on assets
* you can make **collections** of assets (by relating them)
* a **project is simply a view** of a subset of related assets

## Roadmap

### Movie assets
These need "sidecar" (ie. related) cue files to find specific clips, or to trim them. Possibly in a *caboose*.
* video file asset ingestion
* audio file asset ingestion
* video caption file asset ingestion

---
(*) a caboose is a file "secretly" appended to another file (likely binary) to provide additional information about the file.
