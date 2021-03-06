'''
Represents a data set (file) and the data variables it contains.
'''

import sys
import pyferret

_anonymous_dataset_qualifier = '__new_anonymous_dataset__'

class FerDSet(object):
    '''
    A data set and the data variables it contains
    '''

    def __init__(self, filename, title='', qual=''):
        '''
        "Opens" the given NetCDF dataset file in Ferret using the Ferret "USE" command.
        Creates a FerVar for each data variable in this data file and 
        assigns it as an attribute of this class using the variable name.
            filename (string): name of the dataset filename or http address
            title (string): title for the dataset for plots and listing;
                if not given, the Ferret name for the dataset will be used
            qual (string): Ferret qualifiers to be used with the "USE" command
        '''
        self._filename = ''
        self._dsetname = ''
        self._fervars = { }
        self._fervarnames = set()
        if not filename:
            if qual == _anonymous_dataset_qualifier:
                # initialize an new anonymous dataset that will either be 
                # pyferret.anondset or will be modified by a subclass (FerAggDSet)
                return
            else:
                raise ValueError('pyferret.anondset should be used for the anonymous dataset')

        # tell Ferret to open/use this dataset
        cmdstr = 'USE'
        if title:
            cmdstr += '/TITLE="' + str(title) + '"'
        if qual:
            cmdstr += str(qual)
        cmdstr += ' "' + str(filename) + '"'
        (errval, errmsg) = pyferret.run(cmdstr)
        if errval != pyferret.FERR_OK:
            raise ValueError(errmsg)

        # record the filename and Ferret dataset name 
        self._filename = filename
        # need to use the filename as given as the dataset name to avoid possible abiguity
        self._dsetname = filename
        # create a FerVar for each variable in this dataset
        namesdict = pyferret.getstrdata('..varnames')
        for varname in namesdict['data'].flatten():
            if sys.version_info[0] > 2:
                # For Python3.x, namesdict['data'] is a NumPy array of bytes; convert to unicode
                varname = str(varname, 'UTF-8')
            # create a FerVar representing this existing Ferret file variable
            filevar = pyferret.FerVar()
            filevar._markasknownvar(varname, self._dsetname, True)
            # assign this FerVar - uppercase the variable name keys to make case-insensitive
            self._fervars[varname.upper()] = filevar
            # keep a original-case version of the name
            self._fervarnames.add(varname)


    def __repr__(self):
        '''
        Representation to recreate this FerDataSet.
        Also includes the variable names as variables can be added after creation.
        '''
        infostr = "FerDSet('%s') with variables %s" % \
                  (self._filename, str(self.fernames(sort=True)))
        return infostr


    def __eq__(self, other):
        '''
        Two FerDSets are equal if their filenames, datasetnames, and 
        dictionary of FerVar variables are all equal.  All string values 
        are compared case-insensitive.
        '''
        if not isinstance(other, FerDSet):
            return NotImplemented
        if self._filename.upper() != other._filename.upper():
            return False
        if self._dsetname.upper() != other._dsetname.upper():
            return False
        if self._fervars != other._fervars:
            return False
        return True


    def __ne__(self, other):
        '''
        Two FerDSets are not equal if their filenames, datasetnames, or
        dictionary of FerVar variables are not equal.  All string values 
        are compared case-insensitive.
        '''
        if not isinstance(other, FerDSet):
            return NotImplemented
        return not self.__eq__(other)


    def __len__(self):
        '''
        Returns the number of Ferret variables associated with this dataset
        '''
        return len(self._fervars)


    def __getitem__(self, name):
        '''
        Return the Ferret variable (FerVar) with the given name.
        '''
        if not isinstance(name, str):
            raise TypeError('name key is not a string')
        return self._fervars[name.upper()]


    def __setitem__(self, name, value):
        '''
        Creates a copy of value (FerVar), assigns it to Ferret identified by 
        name (string), and adds this copy to this dataset, identified by name.
        '''
        if not isinstance(name, str):
            raise TypeError('name key is not a string')
        if not isinstance(value, pyferret.FerVar):
            raise TypeError('value to be assigned is not a FerVar')
        if self._filename and not self._dsetname:
            raise TypeError('this dataset has been closed')
        # if this name is already assigned to a FerVar, first remove the 
        # Ferret definition that is going to be overwritten; otherwise, 
        # Python's delete of the item in garbage collection will wipe out 
        # the (possibly new) definition as some unknown time.
        try:
            self.__delitem__(name)
        except Exception:
            pass
        # make an anonymous copy of the FerVar (or subclass - the copy 
        # method preserves the class type) and assign it in Ferret.
        newvar = value.copy()
        try:
            newvar._assigninferret(name, self._dsetname)
        except ValueError as ex:
            raise TypeError(str(ex))
        # add this FerVar to this dataset using the uppercase name 
        # to make names case-insenstive 
        self._fervars[name.upper()] = newvar
        # keep a original-case version of the name
        self._fervarnames.add(name)


    def __delitem__(self, name):
        '''
        Removes (cancels) the Ferret variable identified by name (string)
        and removes the FerVar from this dataset.
        '''
        if not isinstance(name, str):
            raise TypeError('name key is not a string')
        uppername = name.upper()
        # let the following throw a KeyError if not found
        value = self._fervars[uppername]
        try:
            value._removefromferret()
        except ValueError as ex:
            raise TypeError(str(ex))
        del self._fervars[uppername]
        origname = None
        for myname in self._fervarnames:
            if myname.upper() == uppername:
                origname = myname
                break
        # should always be found at this point
        if origname is None:
            raise KeyError('unexpected unknown variable name ' + name)
        self._fervarnames.remove(origname)


    def __contains__(self, name):
        '''
        Returns whether the Ferret variable name (case insensitive) is in this dataset
        '''
        if not isinstance(name, str):
            return False
        return ( name.upper() in self._fervars )


    def __iter__(self):
        '''
        Returns an iterator over the Ferret variable names (in their original case).
        '''
        return iter(self._fervarnames)


    def __getattr__(self, name):
        '''
        Returns the Ferret variable (FerVar) with the given name (case insensitive).
        Note that this method is only called when the parent object 
        does not have an attribute with this name.
        '''
        try:
            return self.__getitem__(name)
        except KeyError:
            raise AttributeError('no attribute or FerVar with name %s' % name)


    def __setattr__(self, name, value):
        '''
        If value is a FerVar, then creates a copy of this Ferret variable, assigns it 
        to Ferret identified by name (string), and adds it to this dataset identified 
        by name.  If value is not a FerVar, passes this call onto the parent object.
        '''
        if isinstance(value, pyferret.FerVar):
            try:
                self.__setitem__(name, value)
            except TypeError as ex:
                raise AttributeError(str(ex))
        else:
            super(FerDSet, self).__setattr__(name, value)
 

    def __delattr__(self, name):
        '''
        If name is associated with a FerVar, removes (cancels) the Ferret variable 
        identified by name (string) and removes the FerVar from this dataset.
        If name is not associated with FerVar, passes this call onto the parent object.
        '''
        try:
            self.__delitem__(name)
        except TypeError as ex:
            raise AttributeError(str(ex))
        except KeyError:
            try :
                super(FerDSet, self).__delattr__(name)
            except AttributeError:
                raise AttributeError('no attribute or FerVar with name %s' % name)


    def __dir__(self):
        '''
        Returns a list of attributes, include FerVar names, of this object.
        Adds original-case, uppercase, and lowercase FerVar names.
        '''
        mydir = set( dir(super(FerDSet, self)) )
        for name in self.fernames(sort=False):
            mydir.add( name.upper() )
            mydir.add( name.lower() )
        return list(mydir)


    def fernames(self, sort=False):
        '''
        Returns a list of the names (in their original case) of the current 
        Ferret variables associated with this dataset.
            sort (boolean): sort the list of names?
        '''
        namelist = list(self._fervarnames)
        if sort:
            namelist.sort()
        return namelist


    def fervars(self, sort=False):
        '''
        Returns a list of the current Ferret variables associated with this dataset.
            sort (boolean): sort the list of FerVars?
        '''
        varlist = list( self._fervars.values() )
        if sort:
            varlist.sort()
        return varlist


    def close(self):
        '''
        Removes (cancels) all the (non-file) variables in Ferret associated with this dataset,
        then closes (cancels) this dataset in Ferret (which removes the file variables as well).
        Raises a ValueError if there is a problem.
        '''
        # if the dataset is already closed, ignore this command
        if self._filename and not self._dsetname:
            return
        # remove all the Ferret variables associated with this dataset, 
        # ignoring errors from trying to remove file variables.
        for name in self._fervars:
            try:
                # remove this variable from Ferret 
                self._fervars[name]._removefromferret()
            except NotImplementedError:
                pass
        # remove all the FerVar's from _fervars
        self._fervars.clear()
        self._fervarnames = [ ]
        # nothing else to do if an anonymous dataset
        if not self._dsetname:
            return
        # now remove the dataset
        cmdstr = 'CANCEL DATA "%s"' % self._dsetname
        (errval, errmsg) = pyferret.run(cmdstr)
        if errval != pyferret.FERR_OK:
            raise ValueError('unable to remove dataset "%s" in Ferret: %s' % self._dsetname)
        # mark this dataset as closed
        self._dsetname = ''


    def show(self, brief=True, qual=''):
        '''
        Show the Ferret information about this dataset.  This uses the Ferret
        SHOW DATA command to create and display the information.
            brief (boolean): if True (default), a brief report is shown;
                otherwise a full report is shown.
            qual (string): Ferret qualifiers to add to the SHOW DATA command
        If this is the anonymous dataset (no dataset name), the Ferret 
        SHOW VAR/USER command is used instead to show all variables
        created by this anonymous dataset.
        '''
        # if the dataset is closed, ignore this command
        if self._filename and not self._dsetname:
            return
        if not isinstance(qual, str):
            raise ValueError('qual (Ferret qualifiers) must be a string')
        if not self._dsetname:
            cmdstr = 'SHOW VAR/USER'
            if qual:
                cmdstr += qual
        else:
            cmdstr = 'SHOW DATA'
            if not brief:
                cmdstr += '/FULL'
            if qual:
                cmdstr += qual
            cmdstr += ' "'
            cmdstr += self._dsetname
            cmdstr += '"'
        (errval, errmsg) = pyferret.run(cmdstr)
        if errval != pyferret.FERR_OK:
            raise ValueError('Ferret command "%s" failed: %s' % (cmdstr, errmsg))

