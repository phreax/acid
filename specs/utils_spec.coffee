_         = require 'underscore'
sinon     = require 'sinon'
sinonChai = require 'sinon-chai'
chai      = require 'chai'
chai.use sinonChai
{FakeFS}  = require './spec_helper'
utils     = require '../lib/utils'


do chai.should

describe 'buildRegex', ->
  {buildRegex} = utils()
  it 'should return a file regex', ->
    regex = buildRegex ['js','coffee']
    regex.toString().should.equal /\.js$|\.coffee$/.toString()

describe 'walkDir', ->
  tree = [
    'file',
    'file1',
    (dir: ['file2', 'file3']),
  ]
  spy = sinon.spy();

  {walkDir} = utils(new FakeFS(tree))
  walkDir '.',null,spy

  it 'should call cb for every file', ->
    spy.should.have.been.called
    spy.callCount.should.equal 5
  it 'should call with once for every file', ->
    spy.args[0].should.eql ['file',null]
    spy.args[1].should.eql ['file1',null]
    spy.args[3].should.eql ['dir/file2',null]
    spy.args[4].should.eql ['dir/file3',null]

  it 'should call with once for every dir', ->
    spy.args[2].should.eql [null,'dir']

describe 'walkDir with filter', ->
  tree = [
    'file',
    'file1',
    (dir: ['file2', 'file3']),
    (dir2: ['file2.js', 'file3.js']),
  ]
  spy = sinon.spy();

  {walkDir,buildRegex} = utils(new FakeFS(tree))
  regex = buildRegex ['js']
  walkDir '.',regex,spy

  it 'should call cb for every file', ->
    spy.should.have.been.called
    spy.callCount.should.equal 4

  it 'should call with once for every file', ->
    spy.args[2].should.eql ['dir2/file2.js',null]
    spy.args[3].should.eql ['dir2/file3.js',null]

  it 'should call with once for every dir', ->
    spy.args[0].should.eql [null,'dir']
    spy.args[1].should.eql [null,'dir2']

